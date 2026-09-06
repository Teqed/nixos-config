"""Repository diagnostics, input freshness and published closure comparison."""
import argparse
from pathlib import Path
import socket
import subprocess
import time


def probe(args):
    def git(*words):
        return subprocess.check_output([args.git, '-c', 'safe.directory=' + args.repo,
            '-C', args.repo, *words], text=True).strip()
    if args.kind == 'dirty':
        changes = git('status', '--porcelain')
        return (1, 'Uncommitted changes may obstruct unattended updates') if changes else (0, 'Repository clean')
    if args.kind == 'sync':
        ahead, behind = map(int, git('rev-list', '--left-right', '--count', 'HEAD...' + args.remote + '/main').split())
        return (1 if ahead or behind else 0), f'Local tracking ref {args.remote}/main: ahead={ahead}, behind={behind} (not fetched by this check)'
    if args.kind == 'inputs':
        stamp = git('log', '-1', '--format=%ct', '--', 'flake.lock')
        if not stamp:
            return 3, 'No lockfile commit found'
        age = time.time() - int(stamp)
        if age < 0:
            return 3, 'Lockfile timestamp is in the future'
        return (1 if age > args.max_age else 0), f'Inputs last committed {age / 86400:.1f} days ago; unchanged inputs do not prove update failure'
    target = (Path(args.repo) / 'result-builds' / args.host).resolve(strict=True)
    if args.host == socket.gethostname():
        running = Path('/run/current-system').resolve(strict=True)
    elif args.remote_probe:
        running = Path(subprocess.check_output([args.ssh, '-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5',
            args.host, 'readlink', '-f', '/run/current-system'], text=True).strip())
    else:
        return 0, 'Published closure exists: ' + target.name
    return (0, 'Running published closure') if running == target else (1, f'Published {target.name}; running {running.name}')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('kind', choices=['dirty', 'sync', 'inputs', 'build'])
    p.add_argument('--repo', required=True)
    p.add_argument('--git')
    p.add_argument('--remote', default='origin')
    p.add_argument('--max-age', type=int, default=259200)
    p.add_argument('--host')
    p.add_argument('--ssh')
    p.add_argument('--remote-probe', action='store_true')
    args = p.parse_args()
    try:
        state, message = probe(args)
    except FileNotFoundError:
        state, message = (2 if args.kind == 'build' else 3), 'Required repository or published closure is missing'
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        state, message = 3, str(error)
    print(message)
    raise SystemExit(state)
