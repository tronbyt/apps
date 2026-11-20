# GitHub Assigned Issues

Shows how many open GitHub issues are assigned to you. Uses the [Search issues API](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) with `assignee:@me is:open is:issue` (pull requests are not included).

## Authentication

Sign in with **GitHub OAuth** on a Tronbyt server that supports it (recommended), or enter a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with at least **public_repo** (use **repo** for private issues).

When OAuth is connected, the app uses that token; otherwise it uses the PAT.
