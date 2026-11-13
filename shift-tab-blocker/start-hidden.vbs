' Launches block-shift-tab.ps1 with no visible console window.
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File """ & dir & "\block-shift-tab.ps1"""
CreateObject("WScript.Shell").Run cmd, 0, False
