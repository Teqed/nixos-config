"""Translate a configured HTTP URL into monitoring-plugin arguments."""
import os
import sys
from urllib.parse import urlsplit


def command(plugin, url, certificate=False):
    parsed = urlsplit(url)
    if parsed.scheme not in ('http', 'https') or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError('Expected an HTTP(S) URL without embedded credentials')
    args = [plugin, '-H', parsed.hostname, '-p', str(parsed.port or (443 if parsed.scheme == 'https' else 80)), '-t', '15']
    if parsed.scheme == 'https':
        args += ['-S', '--sni']
    if certificate:
        if parsed.scheme != 'https':
            raise ValueError('Certificate checks require HTTPS')
        args += ['-C', '14,7']
    else:
        args += ['-u', parsed.path or '/', '-w', '5', '-c', '10']
    return args


if __name__ == '__main__':
    try:
        argv = command(sys.argv[1], sys.argv[2], len(sys.argv) > 3)
        os.execv(argv[0], argv)
    except (OSError, ValueError) as error:
        print(str(error))
        raise SystemExit(3)
