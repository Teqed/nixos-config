"""Execute a Nix-generated manifest of standalone monitoring plugins.

JSON output contract (--json):
  {"version": 1, "complete": bool, "excluded": {id: reason}, "results": [result...]}
complete=false means the run itself failed (manifest unreadable, internal error) and
results only describe that failure; consumers must not treat absent checks as removed.
Each result: {"id", "state", "message", "perfdata", "report", "deferred"}.
deferred=true (probe printed perfdata token deferred=1) means "OK for now, outcome not
yet established" (grace, in-progress retry) and must not count as recovery.
"""
import argparse
import concurrent.futures
import json
import os
import signal
import subprocess
import sys

LABELS = {0: "OK", 1: "WARNING", 2: "CRITICAL", 3: "UNKNOWN"}
OUTPUT_VERSION = 1


def severity(results):
    states = {r["state"] for r in results}
    return next((state for state in (2, 3, 1) if state in states), 0)


def exclusion_reason(check, remote=False, scheduled=False):
    """Why a manifest entry is not eligible for this invocation, or None if it is."""
    if check.get("remote", False):
        if scheduled:
            return "remote checks never run in scheduled reports"
        if not remote:
            return "remote check; pass --remote to run it"
    if scheduled and not check.get("report", True):
        return "report=false; interactive diagnostics are excluded from scheduled reports"
    return None


def select(checks, remote=False, scheduled=False):
    """Return (eligible, excluded) where excluded maps id -> reason."""
    eligible, excluded = {}, {}
    for name, check in checks.items():
        reason = exclusion_reason(check, remote=remote, scheduled=scheduled)
        if reason:
            excluded[name] = reason
        else:
            eligible[name] = check
    return eligible, excluded


def perfdata_flags(perfdata):
    flags = {}
    for token in perfdata.split():
        key, sep, value = token.partition("=")
        if sep:
            flags[key.strip("'")] = value.split(";", 1)[0]
    return flags


def run_check(item):
    name, check = item
    try:
        with subprocess.Popen(check["command"], stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True,
                              start_new_session=True) as process:
            try:
                out, err = process.communicate(timeout=check["timeout"])
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()
                raise TimeoutError("execution timed out") from None
            state = process.returncode if process.returncode in LABELS else 3
            diagnostic, _, perfdata = out.strip().partition("|")
            message = " ".join(diagnostic.splitlines()).strip()
            if not message:
                state, message = 3, "check returned no output"
            if err.strip():
                message += " (stderr: " + " ".join(err.splitlines()) + ")"
            perfdata = perfdata.strip()
            deferred = state == 0 and perfdata_flags(perfdata).get("deferred") == "1"
            result = {"id": name, "state": state, "message": message, "perfdata": perfdata, "deferred": deferred}
    except (OSError, TimeoutError, UnicodeError) as error:
        result = {"id": name, "state": 3, "message": str(error), "perfdata": "", "deferred": False}
    result["report"] = check.get("report", True)
    return result


def failure(message):
    return {"id": "runner", "state": 3, "message": message, "perfdata": "", "report": True, "deferred": False}


def execute(manifest_path, remote=False, scheduled=False, only=None):
    """Run the eligible checks. Returns the JSON output document."""
    try:
        with open(manifest_path) as source:
            manifest = json.load(source)
        if not isinstance(manifest, dict):
            raise ValueError("manifest is not an object")
        eligible, excluded = select(manifest, remote=remote, scheduled=scheduled)
        if only:
            chosen, results = {}, []
            for name in only:
                if name in eligible:
                    chosen[name] = eligible[name]
                elif name in excluded:
                    results.append(failure_for(name, "excluded: " + excluded[name]))
                else:
                    results.append(failure_for(name, "not in manifest"))
            eligible = chosen
        else:
            results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            results.extend(pool.map(run_check, sorted(eligible.items())))
        if not results:
            results = [failure("No checks configured")]
        return {"version": OUTPUT_VERSION, "complete": True, "excluded": excluded, "results": results}
    except (OSError, ValueError) as error:
        return {"version": OUTPUT_VERSION, "complete": False, "excluded": {}, "results": [failure(str(error))]}


def failure_for(name, message):
    return {"id": name, "state": 3, "message": message, "perfdata": "", "report": True, "deferred": False}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--remote", action="store_true", help="Include optional remote diagnostics")
    parser.add_argument("--scheduled", action="store_true",
                        help="Only checks that belong in the daily report (excludes report=false and remote checks)")
    parser.add_argument("--check", action="append", help="Run only this check ID (repeatable); eligibility still applies")
    args = parser.parse_args(argv)
    document = execute(args.manifest, remote=args.remote, scheduled=args.scheduled, only=args.check)
    results = document["results"]
    if args.json:
        print(json.dumps(document))
    else:
        for result in results:
            suffix = ""
            if not result["report"]:
                suffix += "  [interactive only]"
            if result["deferred"]:
                suffix += "  [deferred]"
            print(f"[{LABELS[result['state']]}] {result['id']}: {result['message']}{suffix}")
        if not document["complete"]:
            print("runner did not complete; results above are not a full evaluation")
    return severity(results)


if __name__ == "__main__":
    sys.exit(main())
