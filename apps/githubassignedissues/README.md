# GitHub Assigned Issues

Shows how many open GitHub issues are assigned to you. Uses the [Search issues API](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) with `assignee:@me is:open is:issue` (pull requests are not included).

## Authentication

**Personal access token (default)** — A [GitHub PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with at least **public_repo** (use **repo** for private issues). Works on any Tronbyt server.

**OAuth (Tronbyt server)** — On servers with OAuth support, choose *OAuth* and sign in with a GitHub OAuth client registered in **Settings → OAuth**. Same scopes: `read:user`, `repo`.

Existing installs keep PAT mode until you change **Authentication** to OAuth.
