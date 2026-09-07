import contextlib
import io
import json
import os
import tempfile
import threading
import unittest
from pathlib import Path
import unittest.mock
from unittest.mock import patch

import agent_mail as am

CFG = {"mode": "local", "hub": "hub", "domain": "thoughtful", "identities": {}, "dsn_timeout": 1}


def make_maildir(root):
    box = Path(root) / "Maildir"
    for d in ("tmp", "new", "cur"):
        (box / d).mkdir(parents=True)
    return box


def deliver(box, msg, name=None):
    p = box / "new" / (name or f"{len(list((box / 'new').iterdir()))}.test")
    p.write_bytes(msg.as_bytes() if hasattr(msg, "as_bytes") else msg)
    return p


class ComposeTests(unittest.TestCase):
    def test_headers_and_task(self):
        msg = am.compose(CFG, ["repo-nixos-config"], "hello", "body", new_task=True, model="fable/1.0")
        self.assertRegex(msg["X-Task-ID"], am.TASK_RE)
        self.assertTrue(msg["Subject"].startswith(f"[{msg['X-Task-ID']}] hello"))
        self.assertEqual(msg["To"], "repo-nixos-config@thoughtful")
        self.assertEqual(msg["X-Agent-Model"], "fable1.0")
        self.assertIn("@thoughtful>", msg["Message-ID"])

    def test_reply_threads(self):
        msg = am.compose(CFG, ["teq"], "re", "b", reply_to="abc@thoughtful", task="ops#abcdef")
        self.assertEqual(msg["In-Reply-To"], "<abc@thoughtful>")
        self.assertEqual(msg["References"], "<abc@thoughtful>")
        self.assertEqual(msg["Subject"], "[ops#abcdef] re")

    def test_validation_rejects(self):
        for bad in ("../x", "a/b", "A", "", "x" * 70, "te q"):
            with self.assertRaises(ValueError, msg=bad):
                am.compose(CFG, [bad], "s", "b")
        for bad in ("nohash", "repo#ab", "repo#" + "a" * 13, "Repo#abcdef", "repo#abc/ef"):
            with self.assertRaises(ValueError, msg=bad):
                am.compose(CFG, ["teq"], "s", "b", task=bad)
        for bad in ("../x", "<a/b@c>", "nope"):
            with self.assertRaises(ValueError, msg=bad):
                am.validate_msgid(bad)

    def test_harness_detection_and_from(self):
        with patch.dict(os.environ, {"CLAUDECODE": "1"}, clear=False), \
                patch.object(am, "current_user", return_value="agent"):
            name, addr, harness = am.sender_identity(CFG)
            self.assertEqual((addr, harness), ("agent@thoughtful", "claude"))
            self.assertTrue(name.startswith("claude agent ("))
        with patch.dict(os.environ, {}, clear=True), patch.object(am, "current_user", return_value="teq"):
            self.assertEqual(am.sender_identity(CFG)[1:], ("teq@thoughtful", None))
        self.assertEqual(am.detect_harness({"CODEX_SANDBOX": "1"}), "codex")
        self.assertEqual(am.detect_harness({"PRIME_AGENT_KERNEL_PYTHON": "x"}), "prime")
        self.assertEqual(am.detect_harness({"AGENT_MAIL_HARNESS": "luna"}), "luna")


    def test_project_name_sources(self):
        self.assertEqual(am.project_name("/tmp/x", env={"AGENT_MAIL_PROJECT": "My Proj"}), "my-proj")
        fake = unittest.mock.Mock(returncode=0, stdout="/home/teq/Repos/Foo_Bar\n")
        with patch.object(am.subprocess, "run", return_value=fake):
            self.assertEqual(am.project_name("/tmp/x", env={}), "foo-bar")
        with patch.object(am.subprocess, "run", side_effect=OSError):
            self.assertEqual(am.project_name("/tmp/plain.dir", env={}), "plain-dir")

    def test_new_task_and_subject_lift(self):
        m = am.compose(CFG, ["agent+claude"], "hi", "b", new_task=True, project="foo")
        self.assertRegex(m["X-Task-ID"], r"^foo#[0-9a-f]{8}$")
        self.assertTrue(m["Subject"].startswith("[foo#"))
        m = am.compose(CFG, ["teq"], "[foo#abc12345] reply", "b")
        self.assertEqual(m["X-Task-ID"], "foo#abc12345")
        self.assertEqual(m["Subject"], "[foo#abc12345] reply")
        with self.assertRaises(ValueError):
            am.compose(CFG, [], "x", "b")

    def test_peers_excludes_self(self):
        cfg = {**CFG, "harnesses": ["claude", "codex", "prime"], "humans": ["teq"]}
        with patch.object(am, "current_user", return_value="agent"):
            self.assertEqual(am.peers(cfg, harness="codex"), ["agent+claude", "agent+prime", "teq"])
        with patch.object(am, "current_user", return_value="teq"):
            self.assertEqual(am.peers(cfg, harness=None), ["agent+claude", "agent+codex", "agent+prime"])

    def test_task_filters(self):
        m = am.compose(CFG, ["teq"], "x", "b", task="foo#abc12345")
        self.assertTrue(am.task_matches(m, project="foo"))
        self.assertFalse(am.task_matches(m, project="bar"))
        self.assertTrue(am.task_matches(m, task="foo#abc12345"))
        self.assertFalse(am.task_matches(m, task="foo#abc12346"))
        self.assertTrue(am.task_matches(m))
        self.assertFalse(am.task_matches(am.compose(CFG, ["teq"], "y", "b"), project="foo"))

class ProxyRewriteTests(unittest.TestCase):
    def test_from_is_rewritten_from_identity_not_wire(self):
        forged = am.compose(CFG, ["teq"], "hi", "body", task="ops#abcdef")
        forged.replace_header("From", "root <root@thoughtful>")
        forged["Sender"] = "root@thoughtful"
        forged["Received"] = "from evil"
        forged["Delivered-To"] = "teq@thoughtful"
        rebuilt = am.strip_untrusted_headers(forged.as_bytes(), "agent+codex", "bubblegum", CFG)
        self.assertEqual(rebuilt["From"], '"codex agent (bubblegum)" <agent@thoughtful>')
        self.assertIsNone(rebuilt.get("Sender"))
        self.assertIsNone(rebuilt.get("Received"))
        self.assertIsNone(rebuilt.get("Delivered-To"))
        self.assertEqual(rebuilt["X-Origin-Host"], "bubblegum")
        self.assertEqual(rebuilt["X-Task-ID"], "ops#abcdef")
        self.assertEqual(rebuilt["To"], "teq@thoughtful")
        self.assertEqual(rebuilt.get_body(("plain",)).get_content().strip(), "body")

    def test_single_agent_key_keeps_claimed_harness_for_display_only(self):
        wire = am.compose(CFG, ["teq"], "hi", "body")
        del wire["X-Agent-Harness"]
        wire["X-Agent-Harness"] = "Codex; rm -rf"
        rebuilt = am.strip_untrusted_headers(wire.as_bytes(), "agent", "bubblegum", CFG)
        self.assertEqual(rebuilt["From"], '"codexrm-rf agent (bubblegum)" <agent@thoughtful>')
        self.assertEqual(rebuilt["X-Agent-Harness"], "codexrm-rf")
        wire2 = am.compose(CFG, ["teq"], "hi", "body")
        del wire2["X-Agent-Harness"]
        wire2["X-Agent-Harness"] = "codex"
        rebuilt2 = am.strip_untrusted_headers(wire2.as_bytes(), "teq", "bubblegum", CFG)
        self.assertEqual(rebuilt2["From"], '"teq (bubblegum)" <teq@thoughtful>')
        self.assertIsNone(rebuilt2.get("X-Agent-Harness"), "a human key must not be able to claim a harness")

    def test_hub_account_boundary(self):
        with tempfile.TemporaryDirectory() as d:
            agent_box = make_maildir(Path(d) / "agent")
            teq_box = make_maildir(Path(d) / "teq")
            private = am.compose(CFG, ["teq"], "private", "for teq only")
            deliver(teq_box, private, "1.p")
            with patch.object(am, "maildir", return_value=agent_box), patch.object(am, "current_user", return_value="agent"), \
                    patch.dict(os.environ, {"SSH_ORIGINAL_COMMAND": f"show {private['Message-ID']}"}), \
                    contextlib.redirect_stderr(io.StringIO()), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(am.proxy_main(["agent@bubblegum"]), am.EX_UNAVAILABLE)
            self.assertEqual([p.name for p in (teq_box / "new").iterdir()], ["1.p"])
            with patch.object(am, "current_user", return_value="agent"), \
                    patch.dict(os.environ, {"SSH_ORIGINAL_COMMAND": "list"}), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(am.proxy_main(["teq@bubblegum"]), am.EX_NOPERM)

    def test_proxy_refuses_paths_and_unknown_verbs(self):
        with patch.object(am, "current_user", return_value="agent"):
            for cmd in ("show ../x", "list --box a/b", "cat /etc/passwd", "sudo", "send; rm -rf /"):
                with patch.dict(os.environ, {"SSH_ORIGINAL_COMMAND": cmd}), contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(am.proxy_main(["agent+codex@bubblegum"]), 2, cmd)

    def test_proxy_bare_send_reads_recipients_from_message(self):
        wire = am.compose(CFG, ["repo-nixos-config"], "hi", "body", task="repo-nixos-config#5ae51b5d")
        with patch.object(am, "current_user", return_value="agent"), patch.object(am, "load_config", return_value=CFG), \
                patch.object(am, "submit", return_value=(0, "<x@thoughtful>")) as submit, \
                patch.dict(os.environ, {"SSH_ORIGINAL_COMMAND": "send"}), patch.object(am.sys, "stdin") as stdin:
            stdin.buffer.read.return_value = wire.as_bytes()
            self.assertEqual(am.proxy_main(["agent@bubblegum"]), 0)
        sent = submit.call_args[0][0]
        self.assertEqual(sent["To"], "repo-nixos-config@thoughtful")
        self.assertEqual(sent["X-Task-ID"], "repo-nixos-config#5ae51b5d")
        self.assertIn("(bubblegum)", sent["From"])
        with patch.object(am, "load_config", return_value={**CFG, "mode": "client"}), \
                contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(am.main(["send"]), am.EX_USAGE)

    def test_proxy_identity_must_match_account(self):
        with patch.object(am, "current_user", return_value="teq"), \
                patch.dict(os.environ, {"SSH_ORIGINAL_COMMAND": "list"}), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(am.proxy_main(["agent+codex@bubblegum"]), am.EX_NOPERM)
            self.assertEqual(am.proxy_main(["Bad@host"]), am.EX_NOPERM)
            self.assertEqual(am.proxy_main(["teq@bad/host"]), am.EX_NOPERM)
        self.assertEqual(am.proxy_main(["nohost"]), am.EX_USAGE)


class MaildirTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.box = make_maildir(self.tmp.name)
        m1 = am.compose(CFG, ["agent+claude"], "one", "b1")
        m1["Delivered-To"] = "agent+claude@thoughtful"
        m2 = am.compose(CFG, ["agent+codex"], "two", "b2")
        m2["Delivered-To"] = "agent+codex@thoughtful"
        self.p1, self.p2 = deliver(self.box, m1, "1.a"), deliver(self.box, m2, "2.b")
        self.m1, self.m2 = m1, m2

    def tearDown(self):
        self.tmp.cleanup()

    def test_list_filters_by_box_and_unread(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            am.cmd_list(self.box, True, "claude", as_json=True)
        rows = json.loads(out.getvalue())
        self.assertEqual([r["subject"] for r in rows], ["one"])
        self.assertTrue(rows[0]["unread"])

    def test_show_marks_seen_atomically_and_concurrently(self):
        mid = self.m1["Message-ID"]
        results = []
        def reader():
            results.append(am.cmd_show(self.box, mid))
        threads = [threading.Thread(target=reader) for _ in range(4)]
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            [t.start() for t in threads]
            [t.join() for t in threads]
        self.assertTrue(all(r == 0 for r in results))
        self.assertEqual(len(list((self.box / "new").iterdir())), 1)
        self.assertEqual([p.name for p in (self.box / "cur").iterdir()], ["1.a:2,S"])
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            am.cmd_list(self.box, True, None, as_json=True)
        self.assertEqual([r["subject"] for r in json.loads(out.getvalue())], ["two"])

    def test_show_rejects_bad_id_and_missing(self):
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(am.cmd_show(self.box, "<missing@thoughtful>"), am.EX_UNAVAILABLE)
            with self.assertRaises(ValueError):
                am.cmd_show(self.box, "../../etc/passwd")

    def test_watch_replays_unread_once(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            am.cmd_watch(self.box, None, once=True)
        lines = out.getvalue().strip().splitlines()
        self.assertEqual(len(lines), 2)
        self.assertTrue(all("\t" in l for l in lines))


    def test_deliver_command_writes_maildir_atomically(self):
        raw = b"Delivered-To: agent+claude@thoughtful\nMessage-ID: <cmd@thoughtful>\nSubject: via command\n\nbody\n"
        dest = am.deliver(self.box, raw)
        self.assertEqual(dest.parent, self.box / "new")
        self.assertEqual(dest.read_bytes(), raw)
        self.assertEqual(list((self.box / "tmp").iterdir()), [])
        self.assertEqual(dest.stat().st_mode & 0o777, 0o600)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            am.cmd_watch(self.box, "claude", once=True)
        self.assertIn("via command", out.getvalue())
        with patch.object(am, "maildir", return_value=self.box), patch.object(am.sys, "stdin") as stdin:
            stdin.buffer.read.return_value = b"Delivered-To: repo-nixos-config@thoughtful\nMessage-ID: <list@thoughtful>\nSubject: via list\n\nbody\n"
            self.assertEqual(am.deliver_main(["agent+codex@thoughtful"]), 0)
        self.assertEqual(len(list((self.box / "new").iterdir())), 4)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            am.cmd_watch(self.box, "codex", once=True)
        self.assertEqual(sorted(l.split("\t")[-1] for l in out.getvalue().splitlines()), ["two", "via list"])


class DsnTests(unittest.TestCase):
    def dsn(self, mid, action):
        return (f"From: MAILER-DAEMON@thoughtful\nTo: agent@thoughtful\nSubject: Successful Mail Delivery Report\n"
                f"Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"\n\n--B\n"
                f"Content-Type: text/plain\n\nok\n--B\nContent-Type: message/delivery-status\n\n"
                f"Reporting-MTA: dns; thoughtful\n\nFinal-Recipient: rfc822; teq@thoughtful\nAction: {action}\n"
                f"Status: 2.0.0\n--B\nContent-Type: text/rfc822-headers\n\nMessage-ID: {mid}\n--B--\n").encode()

    def test_classify_and_wait(self):
        with tempfile.TemporaryDirectory() as d:
            box = make_maildir(d)
            mid = "<x1@thoughtful>"
            deliver(box, self.dsn("<other@thoughtful>", "delivered"), "0.o")
            self.assertIsNone(am.wait_for_dsn(box, mid, 0.3))
            deliver(box, self.dsn(mid, "delivered"), "1.d")
            self.assertEqual(am.wait_for_dsn(box, mid, 1), "delivered")
            deliver(box, self.dsn("<list@thoughtful>", "expanded"), "2.e")
            self.assertEqual(am.wait_for_dsn(box, "<list@thoughtful>", 1), "delivered")
            self.assertTrue(any(p.name.endswith(":2,S") for p in (box / "cur").iterdir()))
            deliver(box, self.dsn("<x2@thoughtful>", "failed"), "2.f")
            self.assertEqual(am.wait_for_dsn(box, "<x2@thoughtful>", 1), "failed")

    def test_submit_reports_each_outcome_distinctly(self):
        with tempfile.TemporaryDirectory() as d:
            box = make_maildir(d)
            msg = am.compose(CFG, ["teq"], "s", "b")
            ok = unittest.mock.Mock(returncode=0, stderr=b"")
            with patch.object(am.subprocess, "run", return_value=ok), patch.object(am, "maildir", return_value=box):
                with patch.object(am, "wait_for_dsn", return_value="delivered"), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(am.submit(msg, CFG)[0], 0)
                with patch.object(am, "wait_for_dsn", return_value="failed"), contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(am.submit(msg, CFG)[0], am.EX_UNAVAILABLE)
                with patch.object(am, "wait_for_dsn", return_value=None), contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(am.submit(msg, CFG)[0], am.EX_TEMPFAIL)
            bad = unittest.mock.Mock(returncode=1, stderr=b"queue full")
            with patch.object(am.subprocess, "run", return_value=bad), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(am.submit(msg, CFG)[0], am.EX_TEMPFAIL)


class ClientTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.agent_key = Path(self.tmp.name) / "agent-key"
        self.agent_key.write_text("k")
        self.human_home = Path(self.tmp.name) / "teq"
        (self.human_home / ".ssh").mkdir(parents=True)
        self.cfg = dict(CFG, mode="client", identities={"agent": str(self.agent_key)})
        self.pw = {"agent": unittest.mock.Mock(pw_dir="/var/lib/agent"), "teq": unittest.mock.Mock(pw_dir=str(self.human_home))}

    def tearDown(self):
        self.tmp.cleanup()

    def test_identity_selection_per_unix_user(self):
        with patch.object(am.pwd, "getpwnam", side_effect=lambda u: self.pw[u]):
            self.assertEqual(am.client_identity(self.cfg, "agent"), str(self.agent_key))
            with self.assertRaises(FileNotFoundError) as ctx:
                am.client_identity(self.cfg, "teq")
            self.assertIn("mail_ed25519", str(ctx.exception))
            self.assertIn("teq@", str(ctx.exception))
            (self.human_home / ".ssh" / "mail_ed25519").write_text("k")
            self.assertEqual(am.client_identity(self.cfg, "teq"), str(self.human_home / ".ssh" / "mail_ed25519"))

    def test_missing_human_key_is_a_clear_unavailable_error_before_ssh(self):
        err = io.StringIO()
        with patch.object(am, "current_user", return_value="teq"), \
                patch.object(am.pwd, "getpwnam", side_effect=lambda u: self.pw[u]), \
                patch.object(am.subprocess, "run") as run, contextlib.redirect_stderr(err):
            self.assertEqual(am.proxy_call(self.cfg, ["list"]), am.EX_UNAVAILABLE)
            self.assertEqual(run.call_count, 0)
        self.assertIn("mail unavailable: no mail identity for teq", err.getvalue())

    def test_unreachable_hub_fails_closed(self):
        down = unittest.mock.Mock(returncode=255, stdout=b"", stderr=b"connect failed")
        with patch.object(am, "current_user", return_value="agent"), \
                patch.object(am.subprocess, "run", return_value=down) as run, contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(am.proxy_call(self.cfg, ["list"]), am.EX_UNAVAILABLE)
            cmd = run.call_args[0][0]
            self.assertIn(str(self.agent_key), cmd)
            self.assertIn("BatchMode=yes", cmd)
            self.assertEqual(cmd[-2:], ["hub", "list"])
        with patch.object(am, "current_user", return_value="agent"), \
                patch.object(am.subprocess, "run", side_effect=am.subprocess.TimeoutExpired("ssh", 1)), \
                contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(am.proxy_call(self.cfg, ["list"]), am.EX_UNAVAILABLE)

    def test_client_send_composes_locally_then_proxies(self):
        ok = unittest.mock.Mock(returncode=0, stdout=b"delivered <m@thoughtful>\n", stderr=b"")
        with patch.object(am, "load_config", return_value=self.cfg), patch.object(am, "current_user", return_value="agent"), \
                patch.object(am.subprocess, "run", return_value=ok) as run, \
                patch.object(am.sys, "stdin", io.StringIO("hello")), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(am.main(["send", "teq", "-s", "x"]), 0)
            sent = run.call_args.kwargs["input"]
            self.assertIn(b"Subject: x", sent)
            self.assertIn(b"To: teq@thoughtful", sent)


if __name__ == "__main__":
    unittest.main()
