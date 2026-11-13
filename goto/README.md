# goto

A PowerShell bookmark manager for quickly navigating to saved directories.

## Connecting to Your PowerShell Profile

`goto` is a function defined inside `goto.ps1`, so the script has to be **dot-sourced** into your session. The easiest way is to do this from your PowerShell profile so it loads every time you open PowerShell.

1. Make sure your profile exists (this creates the file and any missing parent folders):

   ```powershell
   if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
   ```

2. Open your profile in a text editor:

   ```powershell
   notepad $PROFILE
   ```

3. Add the following line, pointing at wherever you saved the script:

   ```powershell
   . "$HOME\Documents\programming\scripts\goto\goto.ps1"
   ```

   > **Important:** The leading `. ` (dot followed by a space) is required. Running `.\goto.ps1` on its own defines `goto` only inside the script's scope, and it disappears as soon as the script finishes.

4. Save and close the file, then restart PowerShell (or run `. $PROFILE`).

> **Note:** If you get an error about execution policy, run this once:
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## Usage

### Navigate to a bookmark

```powershell
goto <name>
goto scripts
```

### Add a bookmark (saves current directory)

```powershell
goto -add <name>
goto -add scripts
```

### Remove a bookmark

```powershell
goto -remove <name>
goto -remove scripts
```

### List all bookmarks

```powershell
goto -list
```

### Show help in the terminal

```powershell
goto -help            # short list of commands
goto -help -usage     # details and examples for every command
goto -help -add       # details for one command (also -remove, -list, -tips)
```

### Show tips

```powershell
goto -tips
```

Press **Tab** after `goto` to autocomplete bookmark names.

---

## Bookmark Storage

Bookmarks are saved to `~\.goto_bookmarks.json` and persist between sessions.

### Default bookmarks

These are available from the start. The first time you add or remove a bookmark, they are saved to the bookmark file together with your change.

| Name      | Path               |
|-----------|--------------------|
| desktop   | `$HOME\Desktop`    |
| downloads | `$HOME\Downloads`  |
| documents | `$HOME\Documents`  |
