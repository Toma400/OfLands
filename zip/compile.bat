@echo off

cd..
nim c ol.nim
nim c config.nim
rcedit-x64 "OfLands.exe" --set-icon "ol.ico"
set RETVAL_OL=%ERRORLEVEL%
rcedit-x64 "OfLandsConfigurator.exe" --set-icon "ol.ico"
set RETVAL_CF=%ERRORLEVEL%

: if both return values are 0, prompts successful compilation message
if %RETVAL_OL%+%RETVAL_CF% LSS 1 (
    echo Compilation successful!
) else (
    echo Compilation failed
)