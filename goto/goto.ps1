# goto.ps1
# A bookmark manager for quickly navigating to saved directories.

function goto {
    param(
        [string]$name,
        [switch]$add,
        [switch]$remove,
        [switch]$list,
        [switch]$help,
        [switch]$usage,
        [switch]$tips
    )

    # Tips shown by 'goto -tips'. Add new tips to this list.
    $tipsList = @(
        "Press Tab after 'goto ' to autocomplete bookmark names (e.g. 'goto sc<Tab>' -> 'goto scripts').",
        "Tab also completes commands: type '-' and press Tab (e.g. 'goto -re<Tab>' -> 'goto -remove')."
    )

    # Detailed help for each feature, shown by 'goto -help -<feature>' and 'goto -help -usage'
    $helpDetails = [ordered]@{
        "navigate" = @(
            "goto <name>",
            "  Changes the current directory to the folder saved under <name>.",
            "  Press Tab after 'goto ' to autocomplete bookmark names.",
            "  Example: goto scripts"
        )
        "add" = @(
            "goto -add <name>",
            "  Saves the current directory as a bookmark called <name>.",
            "  If <name> already exists, it is overwritten with the current directory.",
            "  Example: cd C:\projects\scripts; goto -add scripts"
        )
        "remove" = @(
            "goto -remove <name>",
            "  Deletes the bookmark called <name>. The folder itself is not touched.",
            "  Example: goto -remove scripts"
        )
        "list" = @(
            "goto -list",
            "  Shows every saved bookmark and the folder it points to, sorted by name.",
            "  Example: goto -list"
        )
        "tips" = @(
            "goto -tips",
            "  Shows handy tips for getting the most out of goto.",
            "  Example: goto -tips"
        )
        "help" = @(
            "goto -help [-usage | -add | -remove | -list | -tips]",
            "  With no extra flag, shows a short list of commands.",
            "  With -usage, shows details for every command.",
            "  With a command flag, shows details for just that command.",
            "  Example: goto -help -add"
        )
    }

    # Path to the file where bookmarks are stored
    $bookmarkFile = "$HOME\.goto_bookmarks.json"

    # Load existing bookmarks from disk, or initialize with defaults if file doesn't exist
    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile | ConvertFrom-Json
        $bookmarks = @{}
        $json.PSObject.Properties | ForEach-Object { $bookmarks[$_.Name] = $_.Value }
    } else {
        $bookmarks = @{
            "desktop"   = "$HOME\Desktop"
            "downloads" = "$HOME\Downloads"
            "documents" = "$HOME\Documents"
        }
    }

    # Prints help to the console
    # Usage:   goto -help                -> short list of commands
    #          goto -help -usage         -> details for every command
    #          goto -help -<command>     -> details for one command (e.g. goto -help -add)
    if ($help) {
        $sections = @()
        if ($usage)  { $sections = @($helpDetails.Keys) }
        if ($add)    { $sections += "add" }
        if ($remove) { $sections += "remove" }
        if ($list)   { $sections += "list" }
        if ($tips)   { $sections += "tips" }

        if ($sections.Count -gt 0) {
            Write-Host ""
            $sections | Select-Object -Unique | ForEach-Object {
                $helpDetails[$_] | ForEach-Object { Write-Host $_ }
                Write-Host ""
            }
        } else {
            Write-Host ""
            Write-Host "goto - directory bookmark manager"
            Write-Host ""
            Write-Host "  goto <name>           Go to a bookmark"
            Write-Host "  goto -add <name>      Save the current directory as a bookmark"
            Write-Host "  goto -remove <name>   Delete a bookmark"
            Write-Host "  goto -list            Show all bookmarks"
            Write-Host "  goto -tips            Show usage tips"
            Write-Host "  goto -help            Show this list"
            Write-Host ""
            Write-Host "Use 'goto -help -usage' for details on every command,"
            Write-Host "or 'goto -help -<command>' for one (e.g. goto -help -add)."
            Write-Host ""
        }
        return
    }

    # Prints usage tips
    # Usage:   goto -tips
    if ($tips) {
        Write-Host ""
        Write-Host "Tips:"
        $tipsList | ForEach-Object { Write-Host "  - $_" }
        Write-Host ""
        return
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
        Write-Host "Usage: goto <name> | goto -add <name> | goto -remove <name> | goto -list | goto -tips | goto -help"
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
