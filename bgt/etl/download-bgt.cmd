@echo off
setlocal enabledelayedexpansion

if "%1"=="" (
    echo U moet een doeldirectory opgeven.
    echo Aanroep: %~nx0 ^<doeldir^>
    goto :eof
)

:: Datum die als enddate dient
for /f "tokens=*" %%a in ('date /t') do for %%b in (%%a) do set today=%%b

:: ID's van 64x64 km gebieden om de BGT te downloaden. Let op, de ID's mogen geen voorloopnullen bevatten.
set blocks=39,45,48,50,51,54,55,56,57,58,59,60,61,62,63,74,75,96,97,98,99,104,105,106,107,110,111,145,148,149,150,151,156,157,158,159,180,181,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,224,225,228,229,230

:: Basis URL
set base_url="https://downloads.pdok.nl/service/extract.zip?extractname=bgt^&extractset=citygml^&excludedtypes=plaatsbepalingspunt^&history=true^&tiles=%%7B%%22layers%%22%%3A%%5B%%7B%%22aggregateLevel%%22%%3A4%%2C%%22codes%%22%%3A%%5B{block}%%5D%%7D%%5D%%7D^&enddate=%today%"

:: Download
set doel_dir=%1

:: Ga door alle blokken
:download
for /f "tokens=1,* delims=," %%i in ("%blocks%") do set "block=%%i" &set "blocks=%%j"

set target_file="%doel_dir%\bgt_%block%.zip"
set target_url=%base_url:{block}=!block!%

:download_inner
:: Haal bestand op
echo Downloading blok %block% ...
del /f "%target_file%" >nul 2>&1
wget -O "%target_file%" --no-check-certificate %target_url%

:: Controleer of het ZIP-bestand geopend kan worden
unzip -l %target_file%
if errorlevel 1 goto download_inner

:: Bestand is gedownload, ga door met het volgende bestand
echo Download blok %block% OK!
echo.
if not "%blocks%"=="" goto download

:: Het downloaden is gereed
echo Klaar, bestanden in %doel_dir%!

endlocal
