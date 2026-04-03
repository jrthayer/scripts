# goto

A PowerShell bookmark manager for quickly navigating to saved directories.

## Connecting to Your PowerShell Profile

To make the `goto` command available every time you open PowerShell, you need to dot-source the script from your profile.

1. Open your PowerShell profile in a text editor:
  
   notepad $PROFILE

   > If the file doesn't exist yet, Notepad will ask if you want to create it — click **Yes**.

2. Add the following line to the file:

   . "C:\Users\jimbo\OneDrive\Desktop\scripts\goto\goto.ps1"


3. Save and close the file, then restart PowerShell.

> **Note:** If you get an error about execution policy, run this once in PowerShell as Administrator:

> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser


---

## Usage

### Navigate to a bookmark

Usage:   goto <name>
Example: goto scripts


### Add a bookmark (saves current directory)

Usage:   goto -add <name>
Example: goto -add scripts


### Remove a bookmark

Usage:   goto -remove <name>
Example: goto -remove scripts


### List all bookmarks

Usage:   goto -list


### Open this help file

Usage:   goto -help


---

## Bookmark Storage

Bookmarks are saved to `~\.goto_bookmarks.json` and persist between sessions.

### Default bookmarks
| Name      | Path                                  |
|-----------|---------------------------------------|
| desktop   -> C:\Users\jimbo\OneDrive\Desktop  |
| downloads -> C:\Users\jimbo\Downloads         |
| documents -> C:\Users\jimbo\Documents         |
