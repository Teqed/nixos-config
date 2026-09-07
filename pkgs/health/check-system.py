import argparse
from pathlib import Path
import subprocess


def probe(kind, systemctl, timedatectl, root=Path('/')):
    if kind == 'failed':
        output = subprocess.check_output([systemctl, '--failed', '--no-legend', '--plain', '--no-pager'], text=True)
        units = [line.split()[0] for line in output.splitlines() if line.strip()]
        return (2, 'Failed units: ' + ', '.join(units)) if units else (0, 'No failed units')
    if kind == 'clock':
        synced = subprocess.check_output([timedatectl, 'show', '-p', 'NTPSynchronized', '--value'], text=True).strip()
        return (0, 'Clock synchronized') if synced == 'yes' else (1, 'Clock is not synchronized')
    current = (root / 'run/current-system').resolve(strict=True)
    booted = (root / 'run/booted-system').resolve(strict=True)
    profile = (root / 'nix/var/nix/profiles/system').resolve(strict=True)
    if profile != current:
        return 1, 'System profile differs from running system (staged boot or test activation); review/reboot'
    changed = [part for part in ('kernel', 'kernel-modules', 'initrd', 'systemd')
               if (booted / part).resolve(strict=True) != (current / part).resolve(strict=True)]
    return (1, 'Reboot pending: ' + ', '.join(changed)) if changed else (0, 'No reboot required')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Host-wide systemd, clock and reboot diagnostics.')
    parser.add_argument('kind', choices=['failed', 'clock', 'reboot'])
    parser.add_argument('systemctl')
    parser.add_argument('timedatectl')
    args = parser.parse_args()
    try:
        state, message = probe(args.kind, args.systemctl, args.timedatectl)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        state, message = 3, str(error)
    print(message)
    raise SystemExit(state)
