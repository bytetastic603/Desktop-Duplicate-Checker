@echo off
setlocal enabledelayedexpansion

:: Target your OneDrive Desktop folder directly
set "TARGET_DIR=%USERPROFILE%\OneDrive - Ministry for Education, Sport, Youth, Research and Innovation\Desktop"

:: 1. Welcome & Introduction Prompt
powershell -Command "$msg = \"Welcome to the Desktop Duplicate File Checker!`n`nThis app will perform the following actions:`n`n1. Scan your desktop for duplicate files and folders (containing Copy).`n2. Generate a timestamped audit report with item count statistics.`n3. Let you safely review, automatically delete, or manually choose what to keep or remove.`n`nWould you like to start the scan now?\"; $w = New-Object -ComObject Wscript.Shell; $res = $w.Popup($msg, 0, 'Welcome - Desktop Duplicate Checker', 4 + 64); exit $res"
if %errorlevel% neq 6 exit /b

:: Generate timestamp
set "TIMESTAMP=%date%_%time%"
set "TIMESTAMP=%TIMESTAMP:/=-%"
set "TIMESTAMP=%TIMESTAMP::=-%"
set "TIMESTAMP=%TIMESTAMP: =_%"
set "TIMESTAMP=%TIMESTAMP:.=-%"

set "REPORT=%TARGET_DIR%\duplicates_report_%TIMESTAMP%.txt"

:: 2. Initialize the report file cleanly first
echo ==================================================== > "%REPORT%"
echo Desktop Duplicate ^& Copy Report - %date% %time% >> "%REPORT%"
echo ==================================================== >> "%REPORT%"

:: 3. Fast background file and folder counting
set /a "TOTAL_FILES=0"
set /a "TOTAL_FOLDERS=0"
for %%f in ("%TARGET_DIR%\*.*") do set /a "TOTAL_FILES+=1"
for /d %%f in ("%TARGET_DIR%\*") do set /a "TOTAL_FOLDERS+=1"
set /a "GRAND_TOTAL=TOTAL_FILES + TOTAL_FOLDERS"

:: Write scan statistics to report
echo Total Items Scanned on Desktop: %GRAND_TOTAL% (%TOTAL_FILES% files, %TOTAL_FOLDERS% folders) >> "%REPORT%"
echo ==================================================== >> "%REPORT%"

echo. >> "%REPORT%"
echo [FOLDERS FOUND WITH "COPY"] >> "%REPORT%"
for /d %%f in ("%TARGET_DIR%\*Copy*") do (
    echo   - %%~nxf  [Modified: %%~tf] >> "%REPORT%"
)

echo. >> "%REPORT%"
echo [FILES FOUND WITH "COPY"] >> "%REPORT%"
for %%f in ("%TARGET_DIR%\*Copy*.*") do (
    echo   - %%~nxf  [Modified: %%~tf] >> "%REPORT%"
)

:: 4. Open the report immediately so user can review
start "" "%REPORT%"

:: 5. Wait 5 seconds to give time to read the report
timeout /t 5 /nobreak >nul

:: 6. Deletion Mode Prompt (Yes = 6 [Automatic], No = 7 [Manual], Cancel = 2 [Skip])
powershell -Command "$msg = \"Scanned %GRAND_TOTAL% total items.`n`nClick YES for Automatic Delete (all at once).`nClick NO for Manual Review (one by one).`nClick CANCEL to skip.\"; $w = New-Object -ComObject Wscript.Shell; $res = $w.Popup($msg, 0, 'Duplicate Checker - Deletion Mode', 3 + 32); exit $res"
set "MODE_CHOICE=%errorlevel%"

:: If user clicks Cancel / Skip (2)
if "%MODE_CHOICE%"=="2" (
    echo. >> "%REPORT%"
    echo [DELETION ACTION: Skipped by user] >> "%REPORT%"
)

:: If user clicks Yes (6) -> Automatic Delete
if "%MODE_CHOICE%"=="6" (
    powershell -Command "$w = New-Object -ComObject Wscript.Shell; $res = $w.Popup('WARNING: This process is irreversible. Are you ABSOLUTELY sure you want to delete all duplicates?', 0, 'Duplicate Checker - Final Warning', 4 + 16); exit $res"
    
    if %errorlevel% equ 6 (
        echo. >> "%REPORT%"
        echo [DELETION ACTION PERFORMED - AUTOMATIC ALL] >> "%REPORT%"
        for /d %%f in ("%TARGET_DIR%\*Copy*") do (
            rd /s /q "%%f" >nul 2>&1
            echo   - DELETED FOLDER: %%~nxf >> "%REPORT%"
        )
        for %%f in ("%TARGET_DIR%\*Copy*.*") do (
            del /f /q "%%f" >nul 2>&1
            echo   - DELETED FILE: %%~nxf >> "%REPORT%"
        )
    ) else (
        echo. >> "%REPORT%"
        echo [DELETION ACTION: Cancelled at final warning] >> "%REPORT%"
    )
)

:: If user clicks No (7) -> Manual Review One by One
if "%MODE_CHOICE%"=="7" (
    echo. >> "%REPORT%"
    echo [DELETION ACTION PERFORMED - MANUAL INTERACTIVE] >> "%REPORT%"
    
    :: Loop through folders for manual review
    for /d %%f in ("%TARGET_DIR%\*Copy*") do (
        powershell -Command "$w = New-Object -ComObject Wscript.Shell; $res = $w.Popup('Do you want to DELETE this duplicate FOLDER?`n`nName: %%~nxf', 0, 'Manual Review - Folder', 4 + 32); exit $res"
        if %errorlevel% equ 6 (
            rd /s /q "%%f" >nul 2>&1
            echo   - DELETED FOLDER: %%~nxf >> "%REPORT%"
        ) else (
            echo   - KEPT FOLDER: %%~nxf >> "%REPORT%"
        )
    )
    
    :: Loop through files for manual review
    for %%f in ("%TARGET_DIR%\*Copy*.*") do (
        powershell -Command "$w = New-Object -ComObject Wscript.Shell; $res = $w.Popup('Do you want to DELETE this duplicate FILE?`n`nName: %%~nxf', 0, 'Manual Review - File', 4 + 32); exit $res"
        if %errorlevel% equ 6 (
            del /f /q "%%f" >nul 2>&1
            echo   - DELETED FILE: %%~nxf >> "%REPORT%"
        ) else (
            echo   - KEPT FILE: %%~nxf >> "%REPORT%"
        )
    )
)

:: 7. Thank You & Report Cleanup Prompt (Yes = Delete report, No = Keep report)
powershell -Command "$msg = \"Thank you for using the Desktop Duplicate File Checker!`n`nWould you like to DELETE the audit report file created on your desktop?`n`(Click YES to delete it, or NO to keep it).\"; $w = New-Object -ComObject Wscript.Shell; $res = $w.Popup($msg, 0, 'Duplicate Checker - Finished', 4 + 64); exit $res"

if %errorlevel% equ 6 (
    :: User clicked Yes -> Delete the report file
    del /f /q "%REPORT%" >nul 2>&1
)

endlocal