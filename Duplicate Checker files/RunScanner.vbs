Set objFSO = CreateObject("Scripting.FileSystemObject")
strCurrentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strBatchFile = strCurrentDir & "\Duplicate check.bat"

CreateObject("WScript.Shell").Run Chr(34) & strBatchFile & Chr(34), 0, False