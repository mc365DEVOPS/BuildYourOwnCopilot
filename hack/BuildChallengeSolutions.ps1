
$excludedFolders = @(
    "\.vs",
    "\ChatAPI\bin",
    "\ChatAPI\manifests",
    "\ChatAPI\obj",
    "\Common\bin",
    "\Common\obj",
    "\Infrastructure\bin",
    "\Infrastructure\obj",
    "\SemanticKernel\bin",
    "\SemanticKernel\obj",
    "\UserPortal\bin",
    "\UserPortal\obj"
)

function Copy-Files {
    param(
        [string]$sourcePath,
        [string]$targetPath
    )

    Get-ChildItem $sourcePath -File | ForEach-Object {
        $file = $_.Name
        $source = Join-Path -Path $sourcePath -ChildPath $file
        $target = Join-Path -Path $targetPath -ChildPath $file
        Write-Host "Copying $source to $target"
        Copy-Item -Path $source -Destination $target -Force
    }
}

function Copy-SolutionFolders {
    param(
        [string]$sourceRelativePath,
        [string]$sourcePath,
        [string]$targetPath
    )

    if (-not (Test-Path -Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath
    }

    Copy-Files -sourcePath $sourcePath -targetPath $targetPath

    Get-ChildItem $sourcePath -Directory | Where-Object { (Join-Path -Path $sourceRelativePath -ChildPath $_.Name) -notin $excludedFolders } | ForEach-Object {
        $folder = $_.Name
        $sourceRelative = Join-Path -Path $sourceRelativePath -ChildPath $folder
        $source = Join-Path -Path $sourcePath -ChildPath $folder
        $target = Join-Path -Path $targetPath -ChildPath $folder
        Write-Host "Copying $source to $target"
        Copy-SolutionFolders -sourceRelativePath $sourceRelative -sourcePath $source -targetPath $target
    }
}

function Change-CodeFile {
    param(
        [string]$filePath,
        [hashtable[]]$replacements
    )

    Write-Output "Starting to change file $filePath..."

    $lines = New-Object System.Collections.ArrayList(, (Get-Content -Path $filePath))

    foreach ($replacement in $replacements) {
        $startingLinePattern = $replacement.StartingLinePattern
        $removedLinesCount = $replacement.RemovePatternLine ? $replacement.RemovedLinesCount + 1 : $replacement.RemovedLinesCount
        $replacementLines = [System.Collections.ArrayList]$replacement.ReplacementLines

        Write-Host "Line pattern lookup: $startingLinePattern"

        $replacementsCount = 0
        $lineIndex = $lines.IndexOf(($lines | Where-Object { $_.Trim() -ieq $startingLinePattern } | Select-Object -First 1))

        while ($lineIndex -ge 0) {

            $replacementsCount++

            if (-not $replacement.RemovePatternLine) {
                $lineIndex++
            }

            Write-Host "Found line at index $lineIndex."
            
            $leadingSpacesCount = $lines[$lineIndex].Length - $lines[$lineIndex].TrimStart().Length
            Write-Host $leadingSpacesCount
            $paddedContent = @{ label = "PaddedContent"; expression = { " " * $leadingSpacesCount + $_ } }
            
            $lines.RemoveRange($lineIndex, $removedLinesCount)
            $lines.InsertRange($lineIndex, [System.Collections.ArrayList]@(($replacementLines | Select-Object $paddedContent | ForEach-Object {$_.PaddedContent})))

            if ($replacement.ReplaceFirstOccurrenceOnly) {
                break
            }

            $lineIndex = $lines.IndexOf(($lines | Where-Object { $_.Trim() -ieq $startingLinePattern } | Select-Object -First 1))
            Write-Host "Next line index: $lineIndex"
        }

        if ($replacementsCount -eq 0) {
            Write-Host -ForegroundColor Red "ERROR: could not find the specified line pattern."
            $global:errorCount++
        } else {
            Write-Host -ForegroundColor Green "Replaced $replacementsCount occurrences."
        }
    }

    Set-Content -Path $filePath -Value $lines
    Write-Output "Finished changing file $filePath."
}

$fullSolutionPath = "D:\Repos\Solliance-MS-BYOC\src"
$challengesRootPath = "E:\Temp\BYOC\hackathon\solutions"
$errorCount = 0

# --------------------------------------------------------------------
# Create Challenge 6 solution (based on the full solution)
# --------------------------------------------------------------------

$challenge6SourcePath = $fullSolutionPath

$challenge6TargetPath = "$challengesRootPath\challenge_6_solution"
Copy-SolutionFolders -sourceRelativePath "\" -sourcePath $challenge6SourcePath -targetPath $challenge6TargetPath

$challenge6TargetPath = "$challengesRootPath\challenge_6_starter"
Copy-SolutionFolders -sourceRelativePath "\" -sourcePath $challenge6SourcePath -targetPath $challenge6TargetPath

$fileChanges = @{
    "Infrastructure\Services\SemanticKernelRAGService.cs" = @(
        @{
            StartingLinePattern = "// This allows us to experiment with different embedding sizes."
            RemovePatternLine = $false
            RemovedLinesCount = 8
            ReplacementLines = @(
                "// TODO: [Challenge 6] Initialize the semantic cache service here."
            )
            ReplaceFirstOccurrenceOnly = $true
        },
        @{
            StartingLinePattern = "var cacheItem = await _semanticCache.GetCacheItem(userPrompt, messageHistory);"
            RemovePatternLine = $true
            RemovedLinesCount = 13
            ReplacementLines = @(
                "// TODO: [Challenge 6] Attempt to retrieve the completion from the semantic cache and return it.",
                "// var cacheItem = ...",
                "// if (!string.IsNullOrEmpty(cacheItem.Completion))",
                "// {",
                "//     return new CompletionResult ...",
                "// }"
            )
            ReplaceFirstOccurrenceOnly = $true
        },
        @{
            StartingLinePattern = "UserPromptTokens = cacheItem.UserPromptTokens,"
            RemovePatternLine = $true
            RemovedLinesCount = 0
            ReplacementLines = @(
                "UserPromptTokens = 0, // TODO: [Challenge 6] Set the user prompt tokens from the cache item."
            )
            ReplaceFirstOccurrenceOnly = $false
        },
        @{
            StartingLinePattern = "UserPromptEmbedding = cacheItem.UserPromptEmbedding.ToArray(),"
            RemovePatternLine = $true
            RemovedLinesCount = 0
            ReplacementLines = @(
                "UserPromptEmbedding = [], // TODO: [Challenge 6] Set the user prompt embedding from the cache item."
            )
            ReplaceFirstOccurrenceOnly = $false
        },
        @{
            StartingLinePattern = "// Add the completion to the semantic memory"
            RemovePatternLine = $false
            RemovedLinesCount = 3
            ReplacementLines = @(
                "// TODO: [Challenge 6] Set the completion and the completion tokens count on the cache item and then add then add it to the semantic memory."
            )
            ReplaceFirstOccurrenceOnly = $true
        }
    )
}

foreach($fileToChange in $fileChanges.Keys) {
    
    Change-CodeFile -filePath "$challenge6TargetPath\$fileToChange" -replacements $fileChanges[$fileToChange]
}

write-host -ForegroundColor (($errorCount -eq 0) ? "Green" : "Red") "Challenge solutions created with $errorCount errors."
