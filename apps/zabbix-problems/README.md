# Zabbix Problems

A configurable Tronbyt/Pixlet app targeting the Zabbix 7.0 LTS JSON-RPC API.
No personal endpoint, API key, external images or private infrastructure data
is bundled. `get_schema()` supplies the installation form. The API token field
is marked `secret=True`; how credentials are stored depends on the host platform.

## Display

- Supports native 64x32 and 128x64 canvases (`supports2x: true`).
- Shows the total number of matching, unresolved problems visible to the token.
- Displays the top 1–3 problems, four seconds each (up to twelve seconds total).
- Highest severity first; newest event first within each severity.
- Each card contains host, problem title, severity, age and page index.
- `A` means acknowledged. Long host names and titles are shortened with `...`.
- Problems beyond the selected top three are included in the total but are not
  cycled through. This bounds animation length and keeps priority alerts visible.
- Defaults: Warning and higher, acknowledged included, suppressed excluded.
- A successful empty result says **No matching problems**. It does not certify
  the health of hosts the token cannot access or problems excluded by filters.
- Demo mode uses fictional events, prominently labelled `DEMO ZABBIX`.

## Zabbix setup

1. Create a dedicated Zabbix user with **Read** access to the desired host groups.
2. Ensure its role permits API access and the `problem.get` and `trigger.get`
   methods. The app does not modify or acknowledge anything in Zabbix.
3. Create an API token for that user and enter it in this app's configuration.
4. Enter the HTTPS frontend URL, for example `https://zabbix.example.com`,
   `https://example.com/zabbix`, or the full URL ending in `/api_jsonrpc.php`.
5. Leave host group IDs blank for all permitted groups, or enter numeric IDs
   separated by commas. Names are not accepted in this field.

The renderer must reach the API directly. A browser SSO login in front of the
endpoint is not API authentication. The proxy must forward the Bearer
Authorization header. TLS verification remains enabled; HTTP URLs are rejected.
There is no external relay or application-specific backend.

## Install through ChuckBuilds LEDMatrix

Upload **zabbix_problems.star** through **Upload .star File**. Keep the parent
**Starlark Apps** plugin enabled, configure this app, save, and add it to rotation.
Use Demo mode first, then disable it and enter URL/token.

Suggested app render interval: 60 seconds. Rotation duration: at least 12 seconds
for three pages. Keep any extra host-side rendered-output cache at 60 seconds
or less while testing. HTTP responses are cached by Pixlet for 60 seconds.

Native 128x64 needs Tronbyt Pixlet's **-2** canvas mode. Magnify **-m 2** only
enlarges a 64x32 render and is not native 2x layout. If the LEDMatrix integration
does not pass `-2`, the 64x32 layout still works and can be scaled to 128x64.

## Local validation

Run from this directory using **Tronbyt Pixlet**:

```sh
pixlet check zabbix_problems.star
pixlet render zabbix_problems.star demo=true -o preview.webp
pixlet render -2 zabbix_problems.star demo=true -o preview@2x.webp
pixlet serve -2 zabbix_problems.star
```

Use the local configuration form for credentials. Do not commit your configured
token, config files, live output images or private screenshots. Preview images
for a public contribution must be generated in Demo mode.

## Error handling and freshness

HTTP errors and JSON-RPC errors display a red status card. Common messages:
`Access denied` (token/proxy), `API error / role?` (API role or parameters),
`Not JSON / SSO?` (HTML login page), `Invalid group IDs` (configuration).
No token or server response body is printed by this app.

Starlark has no try/except: DNS, TLS, connection failures and malformed JSON
can abort rendering before the app can draw an error card. A host may retain
the last successful image. The app requests `max_age=180`, but enforcement
depends on the display host; verify expiration behaviour on your installation.
This display is an overview, not a substitute for Zabbix alerting.

API count and detail calls are separate, cached snapshots. A problem resolved
between requests can temporarily make the count and cards differ. A positive
count without retrievable cards yields `State changed`, never a healthy card.

## Publication

Copy this directory to `apps/zabbixproblems/` in a fork of `tronbyt/apps`.
The manifest uses the repository's field names and identifies the author as
`Silas Suessmilch` (GitHub: `ex0th`). Run the checks above,
generate the two demo previews, review current repository contribution rules,
and submit a pull request. Nothing in this package has been published upstream.

This initial version has offline API/logic tests; it has **not yet been run
under Pixlet or tested against a live Zabbix server**. The top-level
`tests/test_logic.py` executes only the Python-compatible subset with mock
modules and is not a replacement for a Starlark interpreter or pixel-layout test.

Sources:
- https://github.com/tronbyt/apps
- https://github.com/tronbyt/pixlet/blob/main/docs/2x_apps.md
- https://github.com/tronbyt/pixlet/blob/main/docs/widgets.md
- https://www.zabbix.com/documentation/7.0/en/manual/api
- https://www.zabbix.com/documentation/7.0/en/manual/api/reference/problem/get
- https://www.zabbix.com/documentation/7.0/en/manual/api/reference/trigger/get

SPDX-License-Identifier: Apache-2.0
