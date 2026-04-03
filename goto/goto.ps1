# goto.ps1
# A bookmark manager for quickly navigating to saved directories.

function goto {
    param(
        [string]$name,
        [switch]$add,
        [switch]$remove,
        [switch]$list,
        [switch]$help
    )

    # Path to the file where bookmarks are stored
    $bookmarkFile = "$HOME\.goto_bookmarks.json"

    # Load existing bookmarks from disk, or initialize with defaults if file doesn't exist
    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile | ConvertFrom-Json
        $bookmarks = @{}
        $json.PSObject.Properties | ForEach-Object { $bookmarks[$_.Name] = $_.Value }
    } else {
        $bookmarks = @{
            "desktop"   = "C:\Users\jimbo\OneDrive\Desktop"
            "downloads" = "C:\Users\jimbo\Downloads"
            "documents" = "C:\Users\jimbo\Documents"
        }
    }

    # Saves the current directory as a named bookmark
    # Usage:   goto -add <name>
    # Example: goto -add scripts
    if ($add) {
        if (-not $name) { Write-Host "Usage: goto -add <name>"; return }
        $bookmarks[$name] = (Get-Location).Path
        $bookmarks | ConvertTo-Json | Set-Content $bookmarkFile
        Write-Host "Saved '$name' -> $($bookmarks[$name])"
    }
    # Removes a named bookmark
    # Usage:   goto -remove <name>
    # Example: goto -remove scripts
    elseif ($remove) {
        if (-not $name) { Write-Host "Usage: goto -remove <name>"; return }
        if ($bookmarks.ContainsKey($name)) {
            $bookmarks.Remove($name)
            $bookmarks | ConvertTo-Json | Set-Content $bookmarkFile
            Write-Host "Removed bookmark '$name'"
        } else {
            Write-Host "No bookmark named '$name' found."
        }
    }
    # Displays all saved bookmarks sorted alphabetically
    # Usage:   goto -list
    elseif ($list) {
        Write-Host "Available bookmarks:"
        $bookmarks.GetEnumerator() | Sort-Object Name | ForEach-Object {
            Write-Host "  $($_.Key) -> $($_.Value)"
        }
    }
    # Opens the README file
    # Usage:   goto -help
    elseif ($help) {
        Invoke-Item "C:\Users\jimbo\OneDrive\Desktop\scripts\goto\README.md"
    }
    # Default: treat $name as a bookmark and navigate to it
    # Usage:   goto <name>
    # Example: goto scripts
    elseif ($name) {
        if ($bookmarks.ContainsKey($name)) {
            Set-Location $bookmarks[$name]
        } else {
            Write-Host "Unknown bookmark: '$name'"
            Write-Host "Run 'goto -list' to see available bookmarks."
        }
    } else {
        Write-Host "Usage: goto <name> | goto -add <name> | goto -remove <name> | goto -list | goto -help"
    }
}

# Tab completion for goto
# Suggests bookmark names when pressing Tab after goto
Register-ArgumentCompleter -CommandName goto -ParameterName name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $bookmarkFile = "$HOME\.goto_bookmarks.json"

    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile | ConvertFrom-Json
        $bookmarkNames = $json.PSObject.Properties.Name
    } else {
        $bookmarkNames = @("desktop", "downloads", "documents")
    }

    $bookmarkNames | Where-Object { $_ -like "$wordToComplete*" }
}
