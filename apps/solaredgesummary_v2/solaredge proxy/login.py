#!/usr/bin/env python3
"""
One-time SolarEdge authorization for the proxy
==============================================

Follows SolarEdge's documented Site Access flow (developer platform docs,
"Authentication", steps 1 to 4):

  1. You open  https://connect.solaredge.com/authorize?client_id=YOUR_CLIENT_ID
  2. You sign in with your mySolarEdge account, pick your site and approve.
  3. SolarEdge sends the browser to the Redirect URI registered on your
     application, adding ?code=...&site_id=... to it.
  4. This script exchanges that code for tokens (JSON POST with exactly
     grant_type, code, client_id, client_secret) and saves them.

The browser will usually end on a "can't connect" page, because nothing listens
at the redirect address. That is expected: copy the full address from the
address bar and paste it here.

Usage:
    python login.py                       # asks for anything it needs
    python login.py --client-id UUID --output /var/lib/solaredge-proxy/token.json

The client secret is read from SOLAREDGE_CLIENT_SECRET or asked for with hidden
input; it is never a command-line argument.
"""

import argparse
import getpass
import json
import os
import sys
import tempfile
from urllib.parse import quote

from solaredge import SolarEdgeError
from solaredge.oauth import AUTHORIZE_URL, exchange_code, parse_callback

DEFAULT_TOKEN_FILE = "/var/lib/solaredge-proxy/token.json"


def atomic_write_json(path, data):
    """Write JSON, mode 600, so a crash can never leave a half-written file."""
    directory = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".tmp-", suffix=".json")
    try:
        with os.fdopen(fd, "w") as fh:
            json.dump(data, fh, indent=2)
            fh.write("\n")
            fh.flush()
            os.fsync(fh.fileno())
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except Exception:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description="Authorize the SolarEdge proxy (one time).")
    parser.add_argument("--client-id", default=os.environ.get("SOLAREDGE_CLIENT_ID"),
                        help="Client ID from the application's Credentials tab (or SOLAREDGE_CLIENT_ID)")
    parser.add_argument("--output", default=os.environ.get("SOLAREDGE_TOKEN_FILE", DEFAULT_TOKEN_FILE),
                        help=f"Where to save the token (default: {DEFAULT_TOKEN_FILE})")
    args = parser.parse_args(argv)

    client_id = (args.client_id or input("Client ID: ")).strip()
    if not client_id:
        print("error: a client ID is required", file=sys.stderr)
        return 2
    client_secret = os.environ.get("SOLAREDGE_CLIENT_SECRET") or getpass.getpass("Client secret (input hidden): ")

    # Exactly the link SolarEdge documents: only the client ID. The redirect
    # address and the scopes come from the application's settings.
    url = f"{AUTHORIZE_URL}?client_id={quote(client_id, safe='')}"
    print("\n1. Open this link in a browser, sign in with your mySolarEdge account,")
    print("   pick your site and approve:\n")
    print(f"   {url}\n")
    print("2. The browser is then sent to your registered Redirect URI. It may show a")
    print("   'can't connect' page. That is fine. Copy the FULL address from the address bar")
    print("   (it contains code= and site_id=). The code is single-use and expires quickly.\n")
    callback_url = input("Paste the full address here: ").strip().strip("\"'")

    try:
        callback = parse_callback(callback_url)
        token = exchange_code(client_id, client_secret, callback.code, site_id=callback.site_id)
    except SolarEdgeError as exc:
        print(f"\nerror: {exc}", file=sys.stderr)
        if "no code" in str(exc).lower():
            print("Paste the whole address from the browser's address bar; it must contain code=...",
                  file=sys.stderr)
        else:
            print("If the message mentions an invalid code, the code was already used or has expired:"
                  " run this script again and paste a fresh address.", file=sys.stderr)
        return 1

    try:
        atomic_write_json(args.output, token.to_dict())
    except OSError as exc:
        print(f"\nerror: could not save {args.output}: {exc}", file=sys.stderr)
        print("The code is now used up, so fix the path or permissions and run this script again.",
              file=sys.stderr)
        return 1
    print(f"\nSaved the token for site {token.site_id} to {args.output} (mode 600).")
    print("Keep that file in one place only: every refresh replaces the refresh token.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
