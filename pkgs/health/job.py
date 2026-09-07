import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import tempfile
import time

SLEEP_STOP_MESSAGE_ID = "8811e6df2a8e40f58a94cea26f8ebf14"


def record_baseline(path, now=None):
    path = Path(path)
    if path.exists():
        return False
    fd, temporary = tempfile.mkstemp(prefix=".baseline-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as output:
            json.dump({"version": 1, "first_attempt": time.time() if now is None else now}, output)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, 0o644)
        try:
            os.link(temporary, path)
        except FileExistsError:
            return False
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
        return True
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def load_baseline(path):
    try:
        data = json.loads(Path(path).read_text())
        stamp = data.get("first_attempt") if isinstance(data, dict) and data.get("version") == 1 else None
        return stamp if type(stamp) in (int, float) and math.isfinite(stamp) else None
    except (OSError, ValueError):
        return None


def record_success(path, now=None):
    path = Path(path)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
        temporary = output.name
        json.dump({"version": 1, "success": time.time() if now is None else now}, output)
        output.flush()
        os.fsync(output.fileno())
    os.replace(temporary, path)


def last_resume_age(journalctl, now=None):
    if not journalctl:
        return None
    try:
        output = subprocess.check_output(
            [journalctl, "-b", "-q", "-n", "1", "-o", "json", "MESSAGE_ID=" + SLEEP_STOP_MESSAGE_ID],
            text=True, stderr=subprocess.DEVNULL, timeout=10)
        line = output.strip().splitlines()[-1] if output.strip() else ""
        if not line:
            return None
        stamp = int(json.loads(line)["__REALTIME_TIMESTAMP"]) / 1e6
    except (OSError, ValueError, KeyError, IndexError, subprocess.SubprocessError):
        return None
    age = (time.time() if now is None else now) - stamp
    return age if age >= 0 else None


def evaluate(service, timer, record, now, uptime, max_age, max_runtime, boot_grace,
             resume_age=None, resume_grace=0, grace_limit=86400, first_attempt=None):
    if service.get("LoadState") != "loaded" or timer.get("LoadState") != "loaded":
        return 2, "Expected service or timer is missing", False
    if timer.get("ActiveState") != "active":
        return 2, "Expected timer is not active", False
    if service.get("ActiveState") == "activating":
        started = int(service.get("ExecMainStartTimestampMonotonic", "0")) / 1e6
        if not started:
            return 3, "Running, but start timestamp unavailable", False
        elapsed = time.clock_gettime(time.CLOCK_MONOTONIC) - started
        if elapsed > max_runtime:
            return 2, "Job exceeded awake runtime limit", False
        if service.get("Result") not in (None, "success"):
            return 0, "Retry running; previous attempt failed", True
        return 0, "Job running", True
    if service.get("ActiveState") == "failed" or service.get("Result") not in (None, "success"):
        return 2, "Last attempt failed: " + service.get("Result", "unknown"), False
    age = None
    if record is not None:
        stamp = record.get("success")
        if record.get("version") != 1 or type(stamp) not in (int, float) or not math.isfinite(stamp):
            return 3, "Invalid success record", False
        age = now - stamp
        if age < 0:
            return 3, "Success record is in the future; check the clock", False
        if age <= max_age:
            return 0, f"Last successful completion {age / 3600:.1f} wall-clock hours ago", False
    if age is not None:
        stale_for = age
    elif first_attempt is not None and now >= first_attempt:
        stale_for = now - first_attempt
    else:
        stale_for = uptime
    grace_eligible = stale_for <= max_age + grace_limit
    if grace_eligible and uptime < boot_grace:
        return 0, "Waiting for catch-up during configured boot grace", True
    if grace_eligible and resume_age is not None and resume_age < resume_grace:
        return 0, f"Waiting for catch-up; resumed from sleep {resume_age / 60:.0f} minutes ago", True
    if record is None:
        return 3, "No persistent success recorded yet", False
    return 1, f"Last successful completion {age / 3600:.1f} wall-clock hours ago; overdue", False


def main():
    parser = argparse.ArgumentParser(description='Persistent job completion records and freshness evaluation.')
    parser.add_argument("action", choices=["record", "baseline", "check"])
    parser.add_argument("--record", required=True)
    parser.add_argument("--baseline", help="First-attempt marker; written only by the 'baseline' action")
    parser.add_argument("--systemctl")
    parser.add_argument("--journalctl", help="Used for resume evidence; resume grace is skipped without it")
    parser.add_argument("--unit")
    parser.add_argument("--max-age", type=int, default=93600)
    parser.add_argument("--max-runtime", type=int, default=7200)
    parser.add_argument("--boot-grace", type=int, default=3600)
    parser.add_argument("--resume-grace", type=int, default=0)
    parser.add_argument("--grace-limit", type=int, default=86400,
                        help="Grace never applies once history is older than max-age + this many seconds")
    args = parser.parse_args()
    if args.action == "record":
        record_success(args.record)
        return 0
    if args.action == "baseline":
        record_baseline(args.baseline or args.record)
        return 0
    deferred = False
    try:
        def properties(suffix):
            output = subprocess.check_output([args.systemctl, "show", args.unit + suffix, "--no-pager"], text=True)
            return dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
        try:
            record = json.loads(Path(args.record).read_text())
            if not isinstance(record, dict):
                raise ValueError("Invalid success record")
        except FileNotFoundError:
            record = None
        now = time.time()
        state, message, deferred = evaluate(
            properties(".service"), properties(".timer"), record,
            now, time.clock_gettime(time.CLOCK_BOOTTIME),
            args.max_age, args.max_runtime, args.boot_grace,
            last_resume_age(args.journalctl, now) if args.resume_grace else None,
            args.resume_grace, args.grace_limit,
            load_baseline(args.baseline) if args.baseline else None)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        state, message = 3, str(error)
    print(message + ("|deferred=1" if deferred else ""))
    return state


if __name__ == "__main__":
    raise SystemExit(main())
