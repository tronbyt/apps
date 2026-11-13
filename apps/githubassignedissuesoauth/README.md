# GitHub Assigned Issues (OAuth)

Same applet as **GitHub Assigned Issues**, but uses [Tronbyt server-managed OAuth](https://github.com/tronbyt/tronbyt-server) instead of a personal access token.

1. Register a [GitHub OAuth App](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app) and add Tronbyt’s redirect URI from **Settings → OAuth**.
2. Create an OAuth client in Tronbyt with GitHub’s authorize and token endpoints.
3. Install this app, pick the client on the config page, and sign in.

Scopes requested: `read:user`, `repo` (private issues need `repo`). Uses the [Search issues API](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) with `assignee:@me`.
