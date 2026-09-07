import argparse
import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch
import urllib.error

import report
import runner
import job
import importlib.util


def load_probe(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


http_probe = load_probe('check-http')
system_probe = load_probe('check-system')
repo_probe = load_probe('check-repo')
github_probe = load_probe('check-github')

SERVICE_OK = {'LoadState': 'loaded', 'ActiveState': 'inactive', 'Result': 'success'}
TIMER_OK = {'LoadState': 'loaded', 'ActiveState': 'active'}


class FakeResponse(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def doc(results, complete=True, excluded=None):
    return {'version': runner.OUTPUT_VERSION, 'complete': complete, 'excluded': excluded or {}, 'results': results}


def res(name, state, deferred=False, message=None):
    return {'id': name, 'state': state, 'message': message or f'{name} {runner.LABELS[state]}',
            'perfdata': '', 'report': True, 'deferred': deferred}


class GithubTokenTests(unittest.TestCase):
    def accepted(self, config_value):
        config = json.dumps({'access-tokens': {'value': config_value}})
        body = json.dumps({'resources': {'core': {'limit': 5000, 'remaining': 4990}}}).encode()
        with patch.object(github_probe.subprocess, 'check_output', return_value=config), \
                patch.object(github_probe.urllib.request, 'urlopen', return_value=FakeResponse(body)) as post:
            state, text = github_probe.probe('/nix')
            header = post.call_args[0][0].get_header('Authorization')
        return state, text, header

    def test_object_form(self):
        state, text, header = self.accepted({'github.com': 'SECRET-OBJ'})
        self.assertEqual((state, header), (0, 'Bearer SECRET-OBJ'))
        self.assertNotIn('SECRET', text)

    def test_list_form(self):
        state, text, header = self.accepted(['gitlab.com=OTHER', 'github.com=SECRET-LIST'])
        self.assertEqual((state, header), (0, 'Bearer SECRET-LIST'))
        self.assertNotIn('SECRET', text)

    def test_string_form(self):
        state, text, header = self.accepted('gitlab.com=OTHER github.com=SECRET-STR')
        self.assertEqual((state, header), (0, 'Bearer SECRET-STR'))
        self.assertNotIn('SECRET', text)

    def test_missing_token(self):
        for value in ('{}', json.dumps({'access-tokens': {'value': {}}}),
                      json.dumps({'access-tokens': {'value': ['gitlab.com=x']}}),
                      json.dumps({'access-tokens': {'value': ''}}),
                      json.dumps({'access-tokens': {'value': {'github.com': ''}}})):
            with patch.object(github_probe.subprocess, 'check_output', return_value=value):
                state, text = github_probe.probe('/nix')
                self.assertEqual(state, 1, value)
                self.assertNotIn('SECRET', text)

    def test_rejected_token_does_not_leak(self):
        for value in ({'github.com': 'SECRET'}, ['github.com=SECRET'], 'github.com=SECRET'):
            config = json.dumps({'access-tokens': {'value': value}})
            with patch.object(github_probe.subprocess, 'check_output', return_value=config), \
                    patch.object(github_probe.urllib.request, 'urlopen',
                                 side_effect=urllib.error.HTTPError('https://api.github.com', 401, 'Unauthorized', {}, None)):
                state, text = github_probe.probe('/nix')
                self.assertEqual(state, 2)
                self.assertNotIn('SECRET', text)


class RunnerSelectionTests(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        ok = [sys.executable, '-c', 'print("fine")']
        self.manifest = Path(self.dir.name) / 'manifest.json'
        self.manifest.write_text(json.dumps({
            'disk': {'command': ok, 'timeout': 5},
            'repo.dirty': {'command': ok, 'timeout': 5, 'report': False},
            'remote.host': {'command': ok, 'timeout': 5, 'remote': True},
        }))

    def tearDown(self):
        self.dir.cleanup()

    def run_main(self, *extra):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = runner.main(['--manifest', str(self.manifest), '--json', *extra])
        return code, json.loads(out.getvalue())

    def ids(self, document):
        return {r['id']: r for r in document['results']}

    def test_interactive_includes_diagnostics_but_not_remote(self):
        code, document = self.run_main()
        self.assertEqual((code, set(self.ids(document))), (0, {'disk', 'repo.dirty'}))
        self.assertIn('remote.host', document['excluded'])
        self.assertFalse(self.ids(document)['repo.dirty']['report'])

    def test_remote_flag_adds_remote_checks(self):
        code, document = self.run_main('--remote')
        self.assertEqual(set(self.ids(document)), {'disk', 'repo.dirty', 'remote.host'})
        self.assertEqual(document['excluded'], {})

    def test_scheduled_excludes_diagnostics_and_remote(self):
        for flags in (['--scheduled'], ['--scheduled', '--remote']):
            code, document = self.run_main(*flags)
            self.assertEqual(set(self.ids(document)), {'disk'}, flags)
            self.assertEqual(set(document['excluded']), {'repo.dirty', 'remote.host'})
            self.assertTrue(document['complete'])

    def test_check_respects_eligibility_and_explains(self):
        code, document = self.run_main('--scheduled', '--check', 'repo.dirty')
        self.assertEqual(code, 3)
        self.assertIn('report=false', self.ids(document)['repo.dirty']['message'])
        code, document = self.run_main('--check', 'remote.host')
        self.assertEqual(code, 3)
        self.assertIn('--remote', self.ids(document)['remote.host']['message'])
        code, document = self.run_main('--remote', '--check', 'remote.host')
        self.assertEqual((code, self.ids(document)['remote.host']['state']), (0, 0))
        code, document = self.run_main('--check', 'nope')
        self.assertEqual((code, self.ids(document)['nope']['message']), (3, 'not in manifest'))
        code, document = self.run_main('--check', 'disk', '--check', 'repo.dirty')
        self.assertEqual(set(self.ids(document)), {'disk', 'repo.dirty'})

    def test_manifest_failure_is_incomplete_not_empty(self):
        self.manifest.write_text('not json')
        code, document = self.run_main('--scheduled')
        self.assertEqual(code, 3)
        self.assertFalse(document['complete'])
        self.assertEqual([r['id'] for r in document['results']], ['runner'])
        code, document = runner.main(['--manifest', '/does/not/exist', '--json']), None
        self.assertEqual(code, 3)


class RunnerExecutionTests(unittest.TestCase):
    def test_perfdata_preserved(self):
        result = runner.run_check(('disk', {'command': [sys.executable, '-c',
            'print("Disk OK | \'free space\'=42%;10;3;0;100 other=2")'], 'timeout': 2}))
        self.assertEqual(result['message'], 'Disk OK')
        self.assertEqual(result['perfdata'], "'free space'=42%;10;3;0;100 other=2")
        self.assertFalse(result['deferred'])

    def test_deferred_flag_only_from_perfdata_on_ok(self):
        deferred = runner.run_check(('j', {'command': [sys.executable, '-c', 'print("waiting|deferred=1")'], 'timeout': 2}))
        self.assertTrue(deferred['deferred'])
        text_only = runner.run_check(('j', {'command': [sys.executable, '-c', 'print("deferred=1 in prose")'], 'timeout': 2}))
        self.assertFalse(text_only['deferred'])
        failing = runner.run_check(('j', {'command': [sys.executable, '-c', 'print("bad|deferred=1"); exit(2)'], 'timeout': 2}))
        self.assertFalse(failing['deferred'])

    def test_empty_output_is_unknown(self):
        result = runner.run_check(('empty', {'command': [sys.executable, '-c', 'pass'], 'timeout': 2}))
        self.assertEqual(result['state'], 3)

    def test_critical_beats_unknown(self):
        self.assertEqual(runner.severity([{'state': 3}, {'state': 2}]), 2)

    def test_plugin_states_and_errors(self):
        for code in (0, 1, 2, 3, 9):
            result = runner.run_check(('example', {
                'command': [sys.executable, '-c', f"print('disk status'); exit({code})"], 'timeout': 2}))
            self.assertEqual(result['state'], code if code < 4 else 3)
        result = runner.run_check(('missing', {'command': ['/does/not/exist'], 'timeout': 1}))
        self.assertEqual(result['state'], 3)

    def test_timeout(self):
        result = runner.run_check(('slow', {
            'command': [sys.executable, '-c', 'import time; time.sleep(10)'], 'timeout': 0.05}))
        self.assertEqual(result['state'], 3)
        self.assertIn('timed out', result['message'])


class ReportTransitionTests(unittest.TestCase):
    def test_resolved_only_when_check_ran_ok(self):
        previous = {'disk': {'state': 1}, 'repo.dirty': {'state': 1}}
        current, body = report.summarize(doc([res('disk', 0)], excluded={'repo.dirty': 'report=false'}), previous)
        self.assertIn('RESOLVED disk', body)
        self.assertIn('DROPPED repo.dirty: report=false', body)
        self.assertNotIn('RESOLVED repo.dirty', body)
        self.assertEqual(current, {})

    def test_policy_removal_drops_once_then_forgets(self):
        current, body = report.summarize(doc([res('disk', 0)]), {'repo.dirty': {'state': 1}})
        self.assertIn('DROPPED repo.dirty: no longer in the manifest', body)
        _, body = report.summarize(doc([res('disk', 0)]), current)
        self.assertEqual(body, '')

    def test_runner_failure_keeps_incidents_unverified(self):
        delivered = {'job.cache-pull': res('job.cache-pull', 1)}
        failed = doc([res('runner', 3, message='manifest unreadable')], complete=False)
        current, body = report.summarize(failed, delivered)
        self.assertIn('RUNNER INCOMPLETE: manifest unreadable', body)
        self.assertIn('UNVERIFIED WARNING job.cache-pull', body)
        self.assertNotIn('DROPPED', body)
        self.assertNotIn('NEW', body)
        self.assertEqual(current, delivered)
        current2, body = report.summarize(doc([res('job.cache-pull', 1)]), current)
        self.assertEqual(body, 'ONGOING WARNING job.cache-pull: job.cache-pull WARNING')
        self.assertEqual(set(current2), {'job.cache-pull'})
        current3, body = report.summarize(failed, {})
        self.assertEqual((current3, body), ({}, 'RUNNER INCOMPLETE: manifest unreadable'))

    def test_deferred_ok_does_not_resolve_and_does_not_alert(self):
        delivered = {'job.cache-pull': res('job.cache-pull', 1)}
        current, body = report.summarize(doc([res('job.cache-pull', 0, deferred=True)]), delivered)
        self.assertIn('DEFERRED WARNING job.cache-pull', body)
        self.assertNotIn('RESOLVED', body)
        self.assertEqual(current, delivered)
        current, body = report.summarize(doc([res('job.cache-pull', 0, deferred=True)]), {})
        self.assertEqual((current, body), ({}, ''))

    def test_overdue_then_resume_grace_then_expiry_then_success(self):
        state = {}
        state, body = report.summarize(doc([res('job.cache-pull', 1)]), state)
        self.assertIn('NEW WARNING job.cache-pull', body)
        state, body = report.summarize(doc([res('job.cache-pull', 0, deferred=True)]), state)
        self.assertIn('DEFERRED WARNING job.cache-pull', body)
        state, body = report.summarize(doc([res('job.cache-pull', 1)]), state)
        self.assertIn('ONGOING WARNING job.cache-pull', body)
        self.assertNotIn('NEW', body)
        state, body = report.summarize(doc([res('job.cache-pull', 0)]), state)
        self.assertEqual((state, body), ({}, 'RESOLVED job.cache-pull'))

    def test_failed_job_retry_then_failure_or_success(self):
        state, body = report.summarize(doc([res('job.flake-update', 2)]), {})
        self.assertIn('NEW CRITICAL', body)
        retry = doc([res('job.flake-update', 0, deferred=True, message='Retry running')])
        state, body = report.summarize(retry, state)
        self.assertIn('DEFERRED CRITICAL job.flake-update', body)
        self.assertEqual(state['job.flake-update']['state'], 2)
        failed_again, body = report.summarize(doc([res('job.flake-update', 2)]), state)
        self.assertIn('ONGOING CRITICAL', body)
        succeeded, body = report.summarize(doc([res('job.flake-update', 0)]), state)
        self.assertEqual((succeeded, body), ({}, 'RESOLVED job.flake-update'))

    def test_severity_transition(self):
        _, body = report.summarize(doc([res('disk', 2)]), {'disk': {'state': 1}})
        self.assertIn('CHANGED CRITICAL', body)

    def test_daily_ongoing_and_recovery(self):
        current, body = report.summarize(doc([res('disk', 1)]), {})
        self.assertIn('NEW', body)
        _, body = report.summarize(doc([res('disk', 1)]), current)
        self.assertIn('ONGOING', body)
        _, body = report.summarize(doc([res('disk', 0)]), current)
        self.assertIn('RESOLVED disk', body)


class ReportDeliveryTests(unittest.TestCase):
    def deliver(self, state, document, urlopen):
        args = argparse.Namespace(runner='unused', dry_run=False)
        completed = subprocess.CompletedProcess([], 1, json.dumps(document))
        with patch.object(report.subprocess, 'run', return_value=completed) as run, \
                patch.dict(report.os.environ, {'NTFY_URL': 'https://example.org', 'NTFY_TOPIC': 'test'}), \
                patch.object(report.urllib.request, 'urlopen', **urlopen), \
                contextlib.redirect_stdout(io.StringIO()):
            report.deliver(args, state)
            self.assertIn('--scheduled', run.call_args[0][0])

    def test_missing_legacy_and_incompatible_state(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'delivered.json'
            self.assertEqual(report.load_state(state), ({}, None))
            (Path(directory) / 'last-nonok').write_text('disk.nix\n')
            incidents, note = report.load_state(state)
            self.assertEqual(incidents, {})
            self.assertIn('Legacy', note)
            for content in ('{"disk": {"state": 1}}', '[]', 'garbage', '{"version": 1, "incidents": {}}'):
                state.write_text(content)
                incidents, note = report.load_state(state)
                self.assertEqual(incidents, {}, content)
                self.assertIn('unreadable or from an older format', note)
            state.write_text(json.dumps({'version': 2, 'incidents': {'disk': {'state': 1}}}))
            self.assertEqual(report.load_state(state), ({'disk': {'state': 1}}, None))

    def test_delivery_writes_version_2_after_post(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'delivered.json'
            self.deliver(state, doc([res('disk', 1)]), {'return_value': FakeResponse(b'')})
            saved = json.loads(state.read_text())
            self.assertEqual((saved['version'], set(saved['incidents'])), (2, {'disk'}))

    def test_failed_delivery_preserves_state_across_transitions(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'delivered.json'
            original = {'version': 2, 'incidents': {'job.cache-pull': res('job.cache-pull', 1)}}
            state.write_text(json.dumps(original))
            offline = {'side_effect': OSError('offline')}
            for document in (doc([res('job.cache-pull', 0)]),
                             doc([res('job.cache-pull', 0, deferred=True)]),
                             doc([res('runner', 3)], complete=False),
                             doc([res('disk', 0)]),
                             doc([res('job.cache-pull', 2)])):
                with self.assertRaises(OSError):
                    self.deliver(state, document, offline)
                self.assertEqual(json.loads(state.read_text()), original)

    def test_dry_run_never_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'delivered.json'
            args = argparse.Namespace(runner='unused', dry_run=True)
            completed = subprocess.CompletedProcess([], 1, json.dumps(doc([res('disk', 1)])))
            with patch.object(report.subprocess, 'run', return_value=completed), \
                    patch.object(report.urllib.request, 'urlopen') as post, \
                    contextlib.redirect_stdout(io.StringIO()):
                report.deliver(args, state)
            self.assertEqual(post.call_count, 0)
            self.assertFalse(state.exists())

    def test_invalid_runner_output_is_rejected(self):
        good = doc([res('a', 0)])
        bad = [
            '[]', '{}',
            json.dumps(dict(good, version=99)),
            json.dumps(dict(good, results=[])),
            json.dumps(dict(good, complete='false')),
            json.dumps(dict(good, complete='true')),
            json.dumps(dict(good, complete=1)),
            json.dumps(dict(good, excluded=['x'])),
            json.dumps(dict(good, excluded={'x': 1})),
            json.dumps(dict(good, results=[dict(res('a', 0), deferred='yes')])),
            json.dumps(dict(good, results=[dict(res('a', 0), deferred=1)])),
            json.dumps(dict(good, results=[dict(res('a', 0), report='true')])),
            json.dumps(dict(good, results=[dict(res('a', 0), state='0')])),
            json.dumps(dict(good, results=[dict(res('a', 0), state=False)])),
            json.dumps(dict(good, results=[dict(res('a', 0), state=True)])),
            json.dumps(dict(good, results=[dict(res('a', 0), state=0.0)])),
            json.dumps(dict(good, results=[dict(res('a', 0), state=1.0)])),
            json.dumps(dict(good, results=[dict(res('a', 0), state=None)])),
            json.dumps(dict(good, results=[dict(res('a', 0), perfdata=None)])),
            json.dumps(dict(good, results=[res('a', 0), res('a', 1)])),
            json.dumps(dict(good, results=['a'])),
        ]
        for payload in bad:
            with self.assertRaises(ValueError, msg=payload):
                report.validate(json.loads(payload))
        self.assertEqual(report.validate(json.loads(json.dumps(good))), good)

    def test_string_complete_cannot_drop_prior_incidents(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'delivered.json'
            original = {'version': 2, 'incidents': {'job.cache-pull': res('job.cache-pull', 2)}}
            state.write_text(json.dumps(original))
            malformed = dict(doc([res('disk', 0)]), complete='false')
            with self.assertRaises(ValueError):
                self.deliver(state, malformed, {'return_value': FakeResponse(b'')})
            self.assertEqual(json.loads(state.read_text()), original)
            for control in (dict(doc([res('disk', 0)]), complete='true'),
                            doc([dict(res('job.cache-pull', 0), deferred='1')]),
                            doc([res('disk', 0), res('disk', 0)]),
                            doc([dict(res('job.cache-pull', 0), state=False)]),
                            doc([dict(res('job.cache-pull', 0), state=True)]),
                            doc([dict(res('job.cache-pull', 0), state=0.0)]),
                            doc([dict(res('job.cache-pull', 0), state=1.0)])):
                with patch.object(report.urllib.request, 'urlopen') as post:
                    with self.assertRaises(ValueError):
                        self.deliver(state, control, {'return_value': FakeResponse(b'')})
                    self.assertEqual(post.call_count, 0)
                self.assertEqual(json.loads(state.read_text()), original)


class JobFreshnessTests(unittest.TestCase):
    def probe(self, record, uptime=5000, resume_age=None, resume_grace=1800, service=None, timer=None):
        return job.evaluate(service or dict(SERVICE_OK), timer or dict(TIMER_OK), record,
                            100000, uptime, 93600, 7200, 3600, resume_age, resume_grace)

    def test_persistent_freshness_and_boot_grace(self):
        self.assertEqual(self.probe({'version': 1, 'success': 90000}), (0, 'Last successful completion 2.8 wall-clock hours ago', False))
        self.assertEqual(self.probe({'version': 1, 'success': 1})[0], 1)
        self.assertEqual(self.probe(None)[0], 3)
        self.assertEqual(self.probe(None, uptime=10)[:1] + self.probe(None, uptime=10)[2:], (0, True))
        self.assertEqual(self.probe({'version': 1, 'success': 1}, uptime=10)[2], True)
        self.assertEqual(self.probe({'version': 1, 'success': 100001})[0], 3)
        self.assertEqual(self.probe({'version': 1, 'success': 'invalid'})[0], 3)

    def test_stale_after_sleep_is_deferred_within_resume_grace(self):
        state, text, deferred = self.probe({'version': 1, 'success': 1}, resume_age=120)
        self.assertEqual((state, deferred), (0, True))
        self.assertIn('resumed from sleep', text)
        self.assertEqual(self.probe(None, resume_age=120)[::2], (0, True))

    def test_resume_grace_expiry_without_success(self):
        self.assertEqual(self.probe({'version': 1, 'success': 1}, resume_age=1800)[::2], (1, False))
        self.assertEqual(self.probe({'version': 1, 'success': 1}, resume_age=99999)[0], 1)
        self.assertEqual(self.probe(None, resume_age=1800)[0], 3)

    def test_grace_is_bounded_by_grace_limit(self):
        def at(age, uptime=5000):
            record = None if age is None else {'version': 1, 'success': 100000 - age}
            return job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), record, 100000, uptime,
                                93600, 7200, 3600, 60, 1800, 86400)
        self.assertEqual(at(100000)[::2], (0, True))
        self.assertEqual(at(180000)[::2], (0, True))
        self.assertEqual(at(180001)[::2], (1, False))
        self.assertEqual(at(7 * 86400)[::2], (1, False))
        self.assertEqual(at(30 * 86400)[::2], (1, False))
        self.assertEqual(at(180001, uptime=10)[::2], (1, False))
        self.assertEqual(at(None, uptime=100000)[::2], (0, True))
        self.assertEqual(at(None, uptime=180001)[::2], (3, False))
        self.assertEqual(at(None, uptime=10)[::2], (0, True))

    def test_multiday_reports_during_resume_grace_eventually_notify(self):
        day = 86400
        last_success = 0
        state, transcript = {}, []
        for d in range(1, 6):
            now = last_success + d * day + 4 * 3600
            st, msg, deferred = job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), {'version': 1, 'success': last_success},
                                             now, 30 * day, 93600, 7200, 3600, 300, 1800, 86400)
            result = {'id': 'job.cache-pull', 'state': st, 'message': msg, 'perfdata': '', 'report': True, 'deferred': deferred}
            state, body = report.summarize(doc([result]), state)
            transcript.append((d, st, deferred, body.split(' ')[0] if body else ''))
        self.assertEqual(transcript[0][1:], (0, True, ''))
        self.assertEqual(transcript[1][1:], (1, False, 'NEW'))
        self.assertEqual(transcript[2][1:], (1, False, 'ONGOING'))
        self.assertEqual(transcript[3][1:], (1, False, 'ONGOING'))
        self.assertEqual(transcript[4][1:], (1, False, 'ONGOING'))
        deferred_day = {'id': 'job.cache-pull', 'state': 0, 'message': 'grace', 'perfdata': '', 'report': True, 'deferred': True}
        state, body = report.summarize(doc([deferred_day]), state)
        self.assertTrue(body.startswith('DEFERRED WARNING'))
        self.assertIn('job.cache-pull', state)
        st, msg, deferred = job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), {'version': 1, 'success': 6 * day},
                                         6 * day + 60, 30 * day, 93600, 7200, 3600, 300, 1800, 86400)
        self.assertEqual((st, deferred), (0, False))
        state, body = report.summarize(doc([res('job.cache-pull', 0)]), state)
        self.assertEqual((state, body), ({}, 'RESOLVED job.cache-pull'))

    def test_missing_history_deadline_survives_reboots(self):
        day = 86400
        first_attempt = 0
        states = []
        for d in range(1, 6):
            now = first_attempt + d * day + 300
            st, msg, deferred = job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), None, now, 300,
                                             93600, 7200, 3600, None, 1800, 86400, first_attempt)
            states.append((st, deferred))
        self.assertEqual(states[0], (0, True))
        self.assertEqual(states[1], (0, True))
        self.assertEqual(states[2], (3, False))
        self.assertEqual(states[3], (3, False))
        self.assertEqual(states[4], (3, False))
        self.assertEqual(job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), None, 30 * day, 300,
                                      93600, 7200, 3600, None, 1800, 86400, None)[::2], (0, True))
        record = {'version': 1, 'success': 6 * day}
        self.assertEqual(job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), record, 6 * day + 3600, 300,
                                      93600, 7200, 3600, None, 1800, 86400, first_attempt)[::2], (0, False))
        self.assertEqual(job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), record, 6 * day + 100000, 300,
                                      93600, 7200, 3600, None, 1800, 86400, first_attempt)[::2], (0, True))
        self.assertEqual(job.evaluate(dict(SERVICE_OK), dict(TIMER_OK), record, 6 * day + 200000, 300,
                                      93600, 7200, 3600, None, 1800, 86400, first_attempt)[::2], (1, False))

    def test_baseline_is_written_once_and_read_defensively(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'baseline.json'
            self.assertIsNone(job.load_baseline(path))
            self.assertTrue(job.record_baseline(path, 100))
            self.assertFalse(job.record_baseline(path, 200))
            self.assertEqual(job.load_baseline(path), 100)
            self.assertEqual([p.name for p in Path(directory).iterdir()], ['baseline.json'])
            path.write_text('garbage')
            self.assertIsNone(job.load_baseline(path))
            path.write_text(json.dumps({'version': 1, 'first_attempt': 'soon'}))
            self.assertIsNone(job.load_baseline(path))

    def test_baseline_creation_is_crash_safe_and_first_writer_wins(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'baseline.json'
            job.record_baseline(path, 100)
            before = path.read_bytes()
            with patch.object(job.json, 'dump', side_effect=KeyboardInterrupt):
                with self.assertRaises(KeyboardInterrupt):
                    job.record_baseline(Path(directory) / 'other.json', 200)
            with patch.object(job.json, 'dump', side_effect=OSError('disk full')):
                with self.assertRaises(OSError):
                    job.record_baseline(Path(directory) / 'other.json', 200)
            self.assertEqual(path.read_bytes(), before)
            self.assertEqual(sorted(p.name for p in Path(directory).iterdir()), ['baseline.json'])
            with patch.object(job.json, 'dump', side_effect=KeyboardInterrupt):
                with self.assertRaises(KeyboardInterrupt):
                    job.record_baseline(Path(directory) / 'fresh.json', 300)
            self.assertFalse((Path(directory) / 'fresh.json').exists())
            self.assertEqual(sorted(p.name for p in Path(directory).iterdir()), ['baseline.json'])
            path.unlink()
            real_link = job.os.link
            def racing_link(src, dst):
                Path(dst).write_text(json.dumps({'version': 1, 'first_attempt': 42}))
                return real_link(src, dst)
            with patch.object(job.os, 'link', side_effect=racing_link):
                self.assertFalse(job.record_baseline(path, 500))
            self.assertEqual(job.load_baseline(path), 42)
            self.assertEqual(sorted(p.name for p in Path(directory).iterdir()), ['baseline.json'])
            (Path(directory) / '.baseline-partial').write_text('{"version": 1, "first_')
            self.assertEqual(job.load_baseline(path), 42)

    def test_check_action_reads_baseline_without_writing(self):
        with tempfile.TemporaryDirectory() as directory:
            record = Path(directory) / 'success.json'
            baseline = Path(directory) / 'baseline.json'
            job.record_baseline(baseline, time.time() - 30 * 86400)
            service = 'LoadState=loaded\nActiveState=inactive\nResult=success\n'
            timer = 'LoadState=loaded\nActiveState=active\n'
            def show(cmd, text):
                return service if cmd[2].endswith('.service') else timer
            out = io.StringIO()
            with patch.object(job.subprocess, 'check_output', side_effect=show), \
                    patch.object(job.time, 'clock_gettime', return_value=10), \
                    patch.object(sys, 'argv', ['job', 'check', '--record', str(record), '--baseline', str(baseline),
                                               '--systemctl', '/s', '--unit', 'u']), \
                    contextlib.redirect_stdout(out):
                code = job.main()
            self.assertEqual(code, 3)
            self.assertNotIn('deferred=1', out.getvalue())
            self.assertEqual(sorted(p.name for p in Path(directory).iterdir()), ['baseline.json'])

    def test_success_after_grace_is_confirmed_not_deferred(self):
        self.assertEqual(self.probe({'version': 1, 'success': 99999}, resume_age=10)[::2], (0, False))

    def test_resume_grace_disabled_or_no_evidence(self):
        self.assertEqual(self.probe({'version': 1, 'success': 1}, resume_age=10, resume_grace=0)[0], 1)
        self.assertEqual(self.probe({'version': 1, 'success': 1}, resume_age=None)[0], 1)

    def test_failures_are_never_suppressed_by_grace(self):
        failed = dict(SERVICE_OK, Result='exit-code')
        self.assertEqual(self.probe(None, uptime=10, service=failed)[::2], (2, False))
        self.assertEqual(self.probe(None, resume_age=10, service=failed)[::2], (2, False))
        inactive = dict(TIMER_OK, ActiveState='inactive')
        self.assertEqual(self.probe(None, uptime=10, timer=inactive)[0], 2)
        self.assertEqual(self.probe(None, resume_age=10, timer=inactive)[0], 2)
        running = dict(SERVICE_OK, ActiveState='activating', ExecMainStartTimestampMonotonic='100000000')
        with patch.object(job.time, 'clock_gettime', return_value=100000):
            self.assertEqual(job.evaluate(running, dict(TIMER_OK), None, 100000, 10, 93600, 7200, 3600, 10, 1800)[::2], (2, False))

    def test_running_and_retry_are_deferred(self):
        running = dict(SERVICE_OK, ActiveState='activating', ExecMainStartTimestampMonotonic='100000000')
        with patch.object(job.time, 'clock_gettime', return_value=200):
            self.assertEqual(job.evaluate(running, dict(TIMER_OK), None, 10000, 9000, 1000, 500, 0)[::2], (0, True))
            retry = dict(running, Result='exit-code')
            state, text, deferred = job.evaluate(retry, dict(TIMER_OK), None, 10000, 9000, 1000, 500, 0)
            self.assertEqual((state, deferred), (0, True))
            self.assertIn('Retry running', text)
        with patch.object(job.time, 'clock_gettime', return_value=1000):
            self.assertEqual(job.evaluate(retry, dict(TIMER_OK), None, 10000, 9000, 1000, 500, 0)[::2], (2, False))

    def test_check_output_carries_deferred_perfdata(self):
        with tempfile.TemporaryDirectory() as directory:
            record = Path(directory) / 'success.json'
            job.record_success(record, time.time() - 100000)
            service = 'LoadState=loaded\nActiveState=inactive\nResult=success\n'
            timer = 'LoadState=loaded\nActiveState=active\n'
            outputs = {'.service': service, '.timer': timer}
            def show(cmd, text):
                return outputs['.service' if cmd[2].endswith('.service') else '.timer']
            out = io.StringIO()
            with patch.object(job.subprocess, 'check_output', side_effect=show), \
                    patch.object(job.time, 'clock_gettime', return_value=10), \
                    patch.object(sys, 'argv', ['job', 'check', '--record', str(record), '--systemctl', '/s',
                                               '--unit', 'u', '--boot-grace', '3600']), \
                    contextlib.redirect_stdout(out):
                code = job.main()
            self.assertEqual(code, 0)
            self.assertTrue(out.getvalue().strip().endswith('|deferred=1'))

    def test_last_resume_age_from_journal(self):
        line = json.dumps({'__REALTIME_TIMESTAMP': '1000000000', 'MESSAGE_ID': job.SLEEP_STOP_MESSAGE_ID})
        with patch.object(job.subprocess, 'check_output', return_value=line + '\n'):
            self.assertEqual(job.last_resume_age('/journalctl', now=1500), 500)
        with patch.object(job.subprocess, 'check_output', return_value=''):
            self.assertIsNone(job.last_resume_age('/journalctl', now=1500))
        with patch.object(job.subprocess, 'check_output', side_effect=subprocess.CalledProcessError(1, 'j')):
            self.assertIsNone(job.last_resume_age('/journalctl', now=1500))
        self.assertIsNone(job.last_resume_age(None))

    def test_success_record_survives_new_probe(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'success.json'
            job.record_success(path, 100)
            job.record_success(path, 200)
            self.assertEqual(json.loads(path.read_text()), {'version': 1, 'success': 200})


class ProbeTests(unittest.TestCase):
    def test_http_url_and_tls_arguments(self):
        args = http_probe.command('/plugin', 'https://cache.example:8443/nix-cache-info?priority=20')
        self.assertIn('8443', args)
        self.assertIn('/nix-cache-info', args)
        self.assertIn('--sni', args)
        self.assertIn('14,7', http_probe.command('/plugin', 'https://example', True))
        with self.assertRaises(ValueError):
            http_probe.command('/plugin', 'http://example', True)
        with self.assertRaises(ValueError):
            http_probe.command('/plugin', 'https://secret:token@example')

    def test_failed_units_do_not_hide_systemctl_errors(self):
        with patch.object(system_probe.subprocess, 'check_output', return_value='broken.service loaded failed failed\n'):
            self.assertEqual(system_probe.probe('failed', '/systemctl', '/timedatectl')[0], 2)
        with patch.object(system_probe.subprocess, 'check_output', side_effect=subprocess.CalledProcessError(1, 'systemctl')):
            with self.assertRaises(subprocess.SubprocessError):
                system_probe.probe('failed', '/systemctl', '/timedatectl')

    def test_input_age_is_separate_from_job_success(self):
        args = argparse.Namespace(kind='inputs', git='/git', repo='/repo', max_age=100)
        with patch.object(repo_probe.subprocess, 'check_output', return_value='100'), \
                patch.object(repo_probe.time, 'time', return_value=1000):
            state, text = repo_probe.probe(args)
            self.assertEqual(state, 1)
            self.assertIn('do not prove update failure', text)


if __name__ == '__main__':
    unittest.main()
