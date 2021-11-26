Import-Module PSWriteColor
. "./Helper.ps1"

# Read configuration
$config=@{}
Get-Content "PullAllRepos.config" | foreach-object -process { 
    $kvp = [regex]::split($_,'=')
    if(($kvp[0].CompareTo("") -ne 0) -and ($kvp[0].StartsWith("[") -ne $True)) { 
        $key = $kvp[0].Trim()
        $value = $kvp[1].Trim()
        $config.Add($key, $value)
    } 
}
$apiVersion = $config.Get_Item("ApiVersion")
$rootUrl = $config.Get_Item("RootUrl")
$userName = $config.Get_Item("UserName")
$token = $config.Get_Item("Token")
$useParallelism = [bool]::Parse($config.Get_Item("UseParallelism"))
$parallelismLimit = [int]$config.Get_Item("ParallelismLimit")
$trackAllBranches = [bool]::Parse($config.Get_Item("TrackAllBranches"))

# Authentication details fore projects
$authorizationHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($userName):$($token)"))
$headers = @{
    "Authorization" = "Basic $($authorizationHeader)"
    "Accept" = "application/json"
}

# Authentication details for repositories
$gitCredentials = "$([uri]::EscapeDataString($userName)):$($token)"

# Get a list of all existing projects
$projectsRequestUrl = "$($rootUrl)/_apis/projects?api-version=$($apiVersion)"
$projectsResponse = Invoke-WebRequest -Headers $headers -Uri $projectsRequestUrl
$remoteProjects = ConvertFrom-Json $projectsResponse.Content

$baseDirectory = Get-Location
$repositories=@{}

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

# Check all projects
foreach($project in $remoteProjects.value) {
    # Create a the project directory if it doesn't exist
    $projectDirectory = "$($baseDirectory)\$($project.name)"

    if(!(Test-Path $projectDirectory)) {
        New-Item -ItemType Directory -Force -Path $projectDirectory
    }

    $projectDirectory = Get-Item $projectDirectory
    PrintProjectHeader($projectDirectory)
    
    $projectUrlString = "$($rootUrl)/$($projectDirectory.Name)"
    $projectUrl = [uri]::EscapeUriString($projectUrlString)

	# Get a list of all repositories in the project
    $repositoriesRequestUrl = "$($projectUrl)/_apis/git/repositories?api-version=$($apiVersion)"
	$repositoriesResponse = Invoke-WebRequest -Headers $headers -Uri $repositoriesRequestUrl
	$remoteRepositories = ConvertFrom-Json $repositoriesResponse.Content
    
	# Map repository details
	foreach ($remoteRepository in $remoteRepositories.value) {
        $repositoryDetails = [PSCustomObject]@{
            Name = $remoteRepository.name
            ProjectDirectory = $projectDirectory
            RepositoryPath =  "$($projectDirectory)\$($remoteRepository.name)"
            RepositoryUrl = $remoteRepository.remoteUrl.Replace("https://", "https://$($gitCredentials)@")
            PullMethod = $function:CloneOrPullRepo
            TrackAllBranches = $trackAllBranches
        }
        $repositories.Add($repositoryDetails.RepositoryPath, $repositoryDetails)
	}
}

# Pull all repositories
if($useParallelism){
    $repositories.Values | ForEach-Object -Parallel {
        # TODO: Find a way to invoke function without dead-locking in parallel and fix this redundant overhead.
        . "./Helper.ps1"
        CloneOrPullRepo($_)
    } -ThrottleLimit $parallelismLimit
} else {
    $repositories.Values | ForEach-Object -Process {
        $_.PullMethod.Invoke($_)
    }
}

$stopwatch.Elapsed
