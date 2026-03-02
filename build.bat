@echo off
set VERSION=1.0.1
set OUTDIR=dist\v%VERSION%
set ADDONDIR=%OUTDIR%\GoblinAssistantHelper

echo Creating %ADDONDIR%...
if not exist "%ADDONDIR%" mkdir "%ADDONDIR%"

echo Copying addon files...
copy /Y GoblinAssistantHelper.lua "%ADDONDIR%\GoblinAssistantHelper.lua"
copy /Y GoblinAssistantHelper.toc "%ADDONDIR%\GoblinAssistantHelper.toc"

echo Packaging ZIP...
powershell -Command "Compress-Archive -Path '%ADDONDIR%' -DestinationPath '%OUTDIR%\GoblinAssistantHelper.zip' -Force"
echo   %OUTDIR%\GoblinAssistantHelper.zip  ^<-- upload this to CurseForge / GitHub Releases

echo.
echo Done! Build output: %OUTDIR%
pause
