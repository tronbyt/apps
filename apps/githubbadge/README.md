# GitHub Badge

Displays the latest status for a given repository in the design of GitHub's Status Badges. This App uses the [list workflow runs](https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow) API from GitHub.

The Personal Access token should be scoped with `repo:read` for whichever repository you want to listen to.

![GitHub Badge for Tidbyt - Success Example](screenshot_success.webp)
![GitHub Badge for Tidbyt - Failing Example](screenshot_failing.webp)
![GitHub Badge for Tidbyt - Loading Example](screenshot_processing.webp)
![GitHub Badge for Tidbyt - Neutral Example](screenshot_cancelled.webp)
![GitHub Badge for Tidbyt - Faulted Example](screenshot_fault.webp)
