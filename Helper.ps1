function CloneOrPullRepo($repository) {
	Write-Color "$($repository.ProjectDirectory.Name) ", $repository.Name -Color DarkGreen, Cyan
	
	# Clone the repository if it doesn't exist
	if(!(Test-Path -Path $repository.RepositoryPath)) {
		git clone $repository.RepositoryUrl $repository.RepositoryPath
	}
	
	# Track all branches
	if($repository.TrackAllBranches){
		git -C $repository.RepositoryPath branch -r | Select-Object -skip 1 | ForEach-Object {
			$branchname = $_.substring($_.indexof("/") + 1)
			if (git -C $repository.RepositoryPath branch --list $branchname)
			{
				Write-Color "$($repository.ProjectDirectory.Name) ", "$($repository.Name) ", "Branch $($branchname) already exists" -Color DarkGreen, DarkCyan, Yellow
			}
			else
			{
				git -C $repository.RepositoryPath branch --track $branchname $_.Trim()
			}
		}
	}

	# Pull
	git -C $repository.RepositoryPath pull --all
}

function PrintProjectHeader($directory) {
	$headerMessage = "Checking repositories under project: "
	$totalMessageLength = $headerMessage.Length + $directory.Name.Length
	$upperBorder = "▀" * $totalMessageLength
	$lowerBorder = "▄" * $totalMessageLength

	$pre = @"
█▀$($upperBorder)▀█
█ 
"@

	$post = @"
 █
█▄$($lowerBorder)▄█
"@

	Write-Color $pre, $headerMessage, $directory.Name, $post -Color Green, White, Green, Green
}
