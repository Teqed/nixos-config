"""Validate the GitHub token configured for this Nix invocation without exposing it."""
import json
import subprocess
import sys
import urllib.error
import urllib.request


def github_token(value):
    """Extract the github.com token from any shape `nix config show --json` uses for access-tokens.value."""
    if isinstance(value, dict):
        token = value.get('github.com')
        return token if isinstance(token, str) and token else None
    if isinstance(value, str):
        value = value.split()
    if isinstance(value, list):
        for entry in value:
            if isinstance(entry, str) and entry.startswith('github.com='):
                token = entry.split('=', 1)[1]
                return token or None
    return None


def probe(nix):
    config = json.loads(subprocess.check_output([nix, 'config', 'show', '--json'], text=True, stderr=subprocess.DEVNULL))
    token = github_token(config.get('access-tokens', {}).get('value'))
    if not token:
        return 1, 'No GitHub access token configured for the checking user'
    request = urllib.request.Request('https://api.github.com/rate_limit', headers={
        'Authorization': 'Bearer ' + token, 'User-Agent': 'flake-health'})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            data = json.load(response)['resources']['core']
        return (1 if data['remaining'] == 0 else 0), f"GitHub token accepted; {data['remaining']}/{data['limit']} requests remaining"
    except urllib.error.HTTPError as error:
        return (2 if error.code == 401 else 3), f'GitHub credential probe returned HTTP {error.code}'


if __name__ == '__main__':
    try:
        state, message = probe(sys.argv[1])
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        state, message = 3, 'Unable to verify GitHub credentials (check Nix configuration and connectivity)'
    print(message)
    raise SystemExit(state)
