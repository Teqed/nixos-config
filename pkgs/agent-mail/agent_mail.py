import argparse
import email
import email.policy
import email.utils
import json
import os
import pwd
import re
import secrets
import socket
import subprocess
import sys
import time
from email.message import EmailMessage
from pathlib import Path

CONFIG_PATH = Path(os.environ.get("AGENT_MAIL_CONFIG", "/etc/agent-mail/config.json"))
ADDRESS_RE = re.compile(r"^[a-z0-9][a-z0-9+._-]{0,63}$")
TASK_RE = re.compile(r"^[a-z0-9-]+#[a-z0-9]{6,12}$")
MSGID_RE = re.compile(r"^<?[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+>?$")
EX_USAGE, EX_UNAVAILABLE, EX_TEMPFAIL, EX_NOPERM = 64, 69, 75, 77
POLICY = email.policy.default.clone(linesep="\n", utf8=True)


def load_config():
    defaults = {"mode": "local", "hub": "thoughtful", "domain": socket.gethostname(),
                "identities": {}, "dsn_timeout": 15}
    try:
        defaults.update(json.loads(CONFIG_PATH.read_text()))
    except (OSError, ValueError):
        pass
    return defaults


def current_user():
    return pwd.getpwuid(os.getuid()).pw_name


def maildir(user=None):
    home = pwd.getpwnam(user).pw_dir if user else pwd.getpwuid(os.getuid()).pw_dir
    return Path(home) / "Maildir"


def detect_harness(env=os.environ):
    if env.get("AGENT_MAIL_HARNESS"):
        return env["AGENT_MAIL_HARNESS"]
    if env.get("CLAUDECODE") or env.get("CLAUDE_CODE_ENTRYPOINT"):
        return "claude"
    if any(k.startswith("CODEX_") for k in env):
        return "codex"
    if any(k.startswith("PRIME_AGENT") for k in env):
        return "prime"
    return None


def sender_identity(config, principal=None, origin_host=None, claimed_harness=None):
    user = principal or current_user()
    host = origin_host or socket.gethostname()
    harness = detect_harness() if principal is None else None
    if "+" in user:
        base, harness = user.split("+", 1)
    else:
        base = user
        if base == "agent" and harness is None and claimed_harness:
            harness = re.sub(r"[^a-z0-9-]", "", claimed_harness.lower())[:32] or None
    if base != "agent":
        harness = None
    address = f"{base}@{config['domain']}"
    name = f"{harness} agent" if base == "agent" and harness else user
    return f"{name} ({host})", address, harness


def validate_address(addr):
    if not ADDRESS_RE.match(addr):
        raise ValueError(f"invalid address: {addr!r}")
    return addr


def validate_task(task):
    if not TASK_RE.match(task):
        raise ValueError(f"invalid X-Task-ID: {task!r}")
    return task


def validate_msgid(mid):
    mid = mid.strip()
    if "/" in mid or not MSGID_RE.match(mid):
        raise ValueError(f"invalid Message-ID: {mid!r}")
    return mid if mid.startswith("<") else f"<{mid}>"


def new_task_id(list_name):
    return f"{list_name}#{secrets.token_hex(4)}"


def compose(config, to, subject, body, reply_to=None, task=None, new_task=False,
            principal=None, origin_host=None, model=None, extra_headers=None, claimed_harness=None):
    msg = EmailMessage(policy=POLICY)
    name, address, harness = sender_identity(config, principal, origin_host, claimed_harness)
    msg["From"] = email.utils.formataddr((name, address))
    msg["To"] = ", ".join(f"{validate_address(t)}@{config['domain']}" if "@" not in t else t for t in to)
    msg["Date"] = email.utils.formatdate(localtime=True)
    msg["Message-ID"] = email.utils.make_msgid(domain=config["domain"])
    if reply_to:
        reply_to = validate_msgid(reply_to)
        msg["In-Reply-To"] = reply_to
        msg["References"] = reply_to
    if new_task:
        task = new_task_id(to[0].split("@")[0])
    if task:
        task = validate_task(task)
        msg["X-Task-ID"] = task
        subject = f"[{task}] {subject}" if not subject.startswith("[") else subject
    msg["Subject"] = subject or "(no subject)"
    if harness:
        msg["X-Agent-Harness"] = harness
    if model:
        msg["X-Agent-Model"] = re.sub(r"[^A-Za-z0-9._-]", "", model)[:64]
    msg["X-Origin-Host"] = origin_host or socket.gethostname()
    for k, v in (extra_headers or {}).items():
        msg[k] = v
    msg.set_content(body)
    return msg


def strip_untrusted_headers(raw, principal, origin_host, config):
    parsed = email.message_from_bytes(raw, policy=POLICY)
    claimed = parsed.get("X-Agent-Harness")
    for h in ("From", "Sender", "Reply-To", "Return-Path", "X-Origin-Host", "Received",
              "Delivered-To", "X-Original-To", "Message-ID", "Date", "X-Agent-Harness"):
        del parsed[h]
    to = [a.strip() for a in (parsed.get("To") or "").split(",") if a.strip()]
    if not to:
        raise ValueError("missing To")
    body = parsed.get_body(preferencelist=("plain",))
    text = body.get_content() if body else ""
    task = parsed.get("X-Task-ID")
    reply_to = parsed.get("In-Reply-To")
    subject = re.sub(r"^\[[^\]]*\]\s*", "", parsed.get("Subject", ""))
    return compose(config, [t.split("@")[0] for t in to], subject, text, reply_to=reply_to,
                   task=task, principal=principal, origin_host=origin_host,
                   model=parsed.get("X-Agent-Model"), claimed_harness=claimed)


def submit(msg, config, wait_dsn=True):
    mid = msg["Message-ID"]
    envelope_from = email.utils.parseaddr(msg["From"])[1]
    cmd = ["sendmail", "-oi", "-t", "-f", envelope_from, "-N", "success,failure"]
    proc = subprocess.run(cmd, input=msg.as_bytes(), capture_output=True)
    if proc.returncode != 0:
        print(f"sendmail failed: {proc.stderr.decode(errors='replace').strip()}", file=sys.stderr)
        return EX_TEMPFAIL, mid
    if not wait_dsn:
        print(f"queued {mid}")
        return 0, mid
    status = wait_for_dsn(maildir(), mid, config.get("dsn_timeout", 15))
    if status == "delivered":
        print(f"delivered {mid}")
        return 0, mid
    if status == "failed":
        print(f"bounced {mid}", file=sys.stderr)
        return EX_UNAVAILABLE, mid
    print(f"queued, delivery unconfirmed {mid}", file=sys.stderr)
    return EX_TEMPFAIL, mid


def classify_dsn(path, mid):
    try:
        raw = path.read_bytes()
    except OSError:
        return None
    if mid.encode() not in raw:
        return None
    m = email.message_from_bytes(raw, policy=POLICY)
    if m.get_content_type() != "multipart/report":
        return None
    text = raw.decode(errors="replace")
    if re.search(r"^Action:\s*delivered", text, re.M | re.I):
        return "delivered"
    if re.search(r"^Action:\s*(failed|delayed)", text, re.M | re.I):
        return "failed"
    return None


def wait_for_dsn(box, mid, timeout):
    deadline = time.monotonic() + timeout
    seen = set()
    while time.monotonic() < deadline:
        for p in sorted((box / "new").glob("*")):
            if p in seen:
                continue
            seen.add(p)
            status = classify_dsn(p, mid)
            if status:
                mark_seen(p)
                return status
        time.sleep(0.2)
    return None


def mark_seen(path):
    target = path.parent.parent / "cur" / (path.name.split(":")[0] + ":2,S")
    try:
        os.rename(path, target)
        return target
    except FileNotFoundError:
        return None


def iter_messages(box, unread_only=False):
    dirs = [box / "new"] + ([] if unread_only else [box / "cur"])
    for d in dirs:
        if not d.is_dir():
            continue
        for p in sorted(d.iterdir(), key=lambda p: p.name):
            try:
                with p.open("rb") as fh:
                    m = email.message_from_binary_file(fh, policy=POLICY)
            except OSError:
                continue
            yield p, m


def box_matches(m, box_name):
    if not box_name:
        return True
    delivered = (m.get("Delivered-To") or m.get("X-Original-To") or "")
    return f"+{box_name}@" in delivered or delivered.startswith(f"{box_name}@")


def find_by_msgid(box, mid):
    for p, m in iter_messages(box):
        if (m.get("Message-ID") or "").strip() == mid:
            return p, m
    return None, None


def cmd_list(box, unread, box_name, as_json=False):
    rows = []
    for p, m in iter_messages(box, unread_only=unread):
        if not box_matches(m, box_name):
            continue
        rows.append({"id": (m.get("Message-ID") or "").strip(), "from": m.get("From", ""),
                     "subject": m.get("Subject", ""), "date": m.get("Date", ""),
                     "task": m.get("X-Task-ID", ""), "unread": p.parent.name == "new"})
    if as_json:
        print(json.dumps(rows))
    else:
        for r in rows:
            flag = "N" if r["unread"] else " "
            print(f"{flag} {r['id']}  {r['from']}  {r['subject']}")
    return 0


def cmd_show(box, mid, as_json=False):
    mid = validate_msgid(mid)
    p, m = find_by_msgid(box, mid)
    if p is None:
        print(f"no such message: {mid}", file=sys.stderr)
        return EX_UNAVAILABLE
    if p.parent.name == "new":
        mark_seen(p)
    if as_json:
        print(json.dumps({k: v for k, v in m.items()} | {"body": m.get_body(("plain",)).get_content()}))
    else:
        sys.stdout.write(m.as_string())
    return 0


def cmd_watch(box, box_name, since=None, poll=1.0, once=False):
    announced = set()
    while True:
        for p, m in iter_messages(box, unread_only=True):
            mid = (m.get("Message-ID") or "").strip()
            if not mid or mid in announced or not box_matches(m, box_name):
                continue
            announced.add(mid)
            print(f"{mid}\t{m.get('From', '')}\t{m.get('Subject', '')}", flush=True)
        if once:
            return 0
        time.sleep(poll)


def client_identity(config, user=None):
    user = user or current_user()
    configured = config.get("identities", {}).get(user)
    identity = Path(configured) if configured else Path(pwd.getpwnam(user).pw_dir) / ".ssh" / "mail_ed25519"
    if not identity.is_file():
        raise FileNotFoundError(
            f"no mail identity for {user} at {identity}; generate one with "
            f"`ssh-keygen -t ed25519 -f {identity} -C mail:{user}@{socket.gethostname()}` and have its public "
            f"half added to the hub's proxyKeys as \"{user}@{socket.gethostname()}\"")
    return str(identity)


def proxy_call(config, argv, stdin_bytes=None):
    try:
        identity = client_identity(config)
    except (FileNotFoundError, KeyError) as error:
        print(f"mail unavailable: {error}", file=sys.stderr)
        return EX_UNAVAILABLE
    cmd = ["ssh", "-T", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "-o", "IdentitiesOnly=yes",
           "-i", identity, config["hub"], *argv]
    try:
        proc = subprocess.run(cmd, input=stdin_bytes, capture_output=True, timeout=config.get("dsn_timeout", 15) + 30)
    except subprocess.TimeoutExpired:
        print("hub timeout (tailnet down?)", file=sys.stderr)
        return EX_UNAVAILABLE
    if proc.returncode == 255:
        print(f"hub unreachable (tailnet down?): {proc.stderr.decode(errors='replace').strip()}", file=sys.stderr)
        return EX_UNAVAILABLE
    for stream, data in ((sys.stdout, proc.stdout), (sys.stderr, proc.stderr)):
        buffer = getattr(stream, "buffer", None)
        if buffer is not None:
            buffer.write(data)
        else:
            stream.write(data.decode(errors="replace"))
    return proc.returncode


def build_parser():
    p = argparse.ArgumentParser(prog="agent-mail")
    p.add_argument("--json", action="store_true")
    sub = p.add_subparsers(dest="verb", required=True)
    s = sub.add_parser("send", help="body on stdin")
    s.add_argument("to", nargs="*")
    s.add_argument("-s", "--subject", default="")
    s.add_argument("-r", "--reply-to", help="Message-ID being answered")
    s.add_argument("--task", help="existing X-Task-ID")
    s.add_argument("--new-task", action="store_true", help="mint an X-Task-ID for the first recipient/list")
    s.add_argument("--model", help="model name for X-Agent-Model")
    s.add_argument("--no-wait", action="store_true", help="do not wait for the delivery DSN (reports 'queued')")
    l = sub.add_parser("list")
    l.add_argument("--unread", action="store_true")
    l.add_argument("--box", help="harness box (Delivered-To extension), e.g. claude")
    sh = sub.add_parser("show")
    sh.add_argument("message_id")
    w = sub.add_parser("watch")
    w.add_argument("--box")
    w.add_argument("--since", help="accepted for compatibility; replay is always all unread")
    w.add_argument("--once", action="store_true")
    return p


def run_local(args, config, principal=None, origin_host=None, raw_stdin=None):
    box = maildir()
    if args.verb == "send":
        if principal is not None:
            msg = strip_untrusted_headers(raw_stdin, principal, origin_host, config)
        else:
            if not args.to:
                raise ValueError("send needs at least one recipient")
            body = sys.stdin.read()
            msg = compose(config, args.to, args.subject, body, reply_to=args.reply_to, task=args.task,
                          new_task=args.new_task, model=args.model or os.environ.get("AGENT_MAIL_MODEL"))
        code, _ = submit(msg, config, wait_dsn=not args.no_wait)
        return code
    if args.verb == "list":
        return cmd_list(box, args.unread, args.box, args.json)
    if args.verb == "show":
        return cmd_show(box, args.message_id, args.json)
    if args.verb == "watch":
        return cmd_watch(box, args.box, once=args.once)
    return EX_USAGE


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    config = load_config()
    args = build_parser().parse_args(argv)
    if config.get("mode") == "client":
        if args.verb == "send":
            if not args.to:
                print("send needs at least one recipient", file=sys.stderr)
                return EX_USAGE
            body = sys.stdin.read()
            msg = compose(config, args.to, args.subject, body, reply_to=args.reply_to, task=args.task,
                          new_task=args.new_task, model=args.model or os.environ.get("AGENT_MAIL_MODEL"))
            return proxy_call(config, ["send"], msg.as_bytes())
        return proxy_call(config, argv)
    try:
        return run_local(args, config)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return EX_USAGE


def proxy_main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) != 1 or "@" not in argv[0]:
        print("usage: agent-mail-proxy <principal>@<host>", file=sys.stderr)
        return EX_USAGE
    principal, origin_host = argv[0].split("@", 1)
    if not ADDRESS_RE.match(principal) or not re.match(r"^[a-z0-9.-]+$", origin_host):
        return EX_NOPERM
    if principal.split("+")[0] != current_user():
        print("identity does not match account", file=sys.stderr)
        return EX_NOPERM
    original = os.environ.get("SSH_ORIGINAL_COMMAND", "").split()
    if not original or any("/" in tok for tok in original):
        print("refused", file=sys.stderr)
        return 2
    allowed = {"send", "list", "show", "watch"}
    verb = next((t for t in original if t in allowed), None)
    if verb is None:
        print("refused", file=sys.stderr)
        return 2
    config = load_config()
    try:
        args = build_parser().parse_args(original)
    except SystemExit:
        return 2
    raw = sys.stdin.buffer.read() if verb == "send" else None
    try:
        return run_local(args, config, principal=principal, origin_host=origin_host, raw_stdin=raw)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return EX_USAGE


def deliver(box, raw):
    for d in ("tmp", "new", "cur"):
        (box / d).mkdir(mode=0o700, parents=True, exist_ok=True)
    name = f"{time.time_ns() // 1000}.P{os.getpid()}Q{secrets.token_hex(4)}.{socket.gethostname()}"
    tmp, dest = box / "tmp" / name, box / "new" / name
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as fh:
        fh.write(raw)
        fh.flush()
        os.fsync(fh.fileno())
    os.link(tmp, dest)
    os.unlink(tmp)
    return dest


def deliver_main():
    try:
        deliver(maildir(), sys.stdin.buffer.read())
    except OSError as error:
        print(f"delivery failed: {error}", file=sys.stderr)
        return EX_TEMPFAIL
    return 0


if __name__ == "__main__":
    sys.exit(main())
