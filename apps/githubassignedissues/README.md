# GitHub Assigned Issues

Shows how many open GitHub issues are assigned to you. Requires a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with at least **public_repo** access (use **repo** if you need private repositories). Uses the [Search issues API](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) with `assignee:@me is:open is:issue` (pull requests are not included).
