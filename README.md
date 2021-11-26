# AzureDevOpsCloneWars
Simple PowerShell script for cloning and pulling all Git repositories in an Azure DevOps organisation.
It's built upon the [basic script](https://blog.rsuter.com/script-to-clone-all-git-repositories-from-your-vsts-collection/) @RicoSuter has blogged years ago.

## Dependencies
The script relies on `PSWriteColor` module for easy colour-formatting of outputs.
You can install it with `Install-Module -Name PSWriteColor` or you can replace usages of `Write-Color` with `Write-Host` if you don't want to install that module for a reason.

## Usage
Copy the script and configuration files (`PullAllRepos.ps1`, `PullAllRepos.config`, `Helper.ps1`) into the folder where you want to clone your repositories.
Edit the `PullAllRepos.config` file and replace the configuration values with your organisation and account details. At the very least, you'll need to replace `RootUrl`, `UserName` and `Token`
You can generate a personal access token on your Azure DevOps portal, and it will only require `Read` access to `Code` and nothing else.
If you want to track all branches of repositories, set `TrackAllBranches` as `True`, if you want to track just the default branches, set it as `False`.

### Running
From that point on, simply execute the `PullAllRepos.ps1` script like this:
```
.\PullAllRepos.ps1
```
Every time you execute the script, it will check all the projects in your Azure DevOps organisation, map them to subdirectories in the current directory, and pull all changes on all branches of all repositories in all projects.
If new repositories are added over time, it will just clone them as it pulls the changes on existing repositories.

## Notes
When this script is used to pull all branches from the remote, it doesn't work well in scenarios where feature branches are deleted after squash merges and then new feature branches are created with the same names.
Or in cases where a force-push was performed on the default branch. But then again, if there are force-pushes flying around, I'm going to assume you have bigger problems.
Anyway, the point is, there's sill work to do around handling those edge cases.
Also, there are some minor performance improvements I still want to make, but so far it works just fine.
I don't imagine that being the case, but if the script's hitting your CPU or network bandwidth too hard, you can reduce the degree of parallelism by reducing the `ParallelismLimit` setting, or by completely disabling it via the `UseParallelism` setting in the configuration.