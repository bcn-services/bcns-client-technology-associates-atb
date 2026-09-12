@echo off
rem ATB Runner verification. Runs the 12 reference cases through the ORIGINAL ATBV3.exe using
rem ATBRunner's batch mode, then compares every output file against the shipped reference hashes.
rem Lines that legitimately change from run to run (date/time/path stamps, listed in volatile.txt)
rem are masked before hashing. Prints IDENTICAL or DIFFERS per case.
setlocal EnableDelayedExpansion
set "HERE=%~dp0"
rem short, space-free work folder (same order ATBRunner's window uses): Public, then LocalAppData, then TEMP
set "ROOT=%PUBLIC%\ATBRun"
if "%PUBLIC%"=="" set "ROOT=%LOCALAPPDATA%\ATBRun"
if "%ROOT%"=="\ATBRun" set "ROOT=%TEMP%\ATBRun"
mkdir "%ROOT%" 2>nul
echo.>"%ROOT%\.w" 2>nul || set "ROOT=%LOCALAPPDATA%\ATBRun"
del "%ROOT%\.w" 2>nul
set "WORK=%ROOT%\verify"
echo ATB Runner verification  (%DATE% %TIME%)
echo folder: %HERE%
echo work:   %WORK%
if not exist "%HERE%ATBRunner.exe" echo ATBRunner.exe missing & exit /b 2
if not exist "%HERE%ATBV3.exe" echo ATBV3.exe missing & exit /b 2
if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%" 2>nul
set /a NID=0
set /a NDF=0
set /a NFAIL=0
set "SUMMARY="
for /f "usebackq tokens=1,2,3,4" %%A in ("%HERE%cases\cases.txt") do call :one %%A %%B %%C %%D
echo.
echo ===== RESULT: %NID% IDENTICAL, %NDF% DIFFERS, %NFAIL% FAILED TO RUN  (of 12 runs)
echo %DATE% %TIME% %NID% IDENTICAL %NDF% DIFFERS %NFAIL% FAILED>>"%HERE%verify-results.txt"
echo Results appended to %HERE%verify-results.txt ; per-case logs under %WORK%
if %NFAIL% NEQ 0 exit /b 3
if %NDF% NEQ 0 exit /b 1
exit /b 0

:one
set "KEY=%~1"
set "CD=%~2"
set "BASE=%~3"
set "SUB=%~4"
if not exist "%WORK%\%SUB%" mkdir "%WORK%\%SUB%"
copy /y "%HERE%cases\%CD%\%BASE%.LIN" "%WORK%\%SUB%\%BASE%.lin" >nul
echo.
echo --- %KEY%: running ATBV3.exe ...
"%HERE%ATBRunner.exe" --lin "%WORK%\%SUB%\%BASE%.lin" --out %BASE%_new --dir "%WORK%\%SUB%" --log "%WORK%\%SUB%\%BASE%.runner.log"
set RC=%ERRORLEVEL%
if %RC% NEQ 0 (
  echo %KEY%: FAILED TO RUN ^(ATBRunner exit %RC%, see %WORK%\%SUB%\%BASE%.runner.log^)
  if %RC% EQU 3 echo   ATBRunner refused: the ATBV3.exe in this folder is not the original ^(hash mismatch^).
  set /a NFAIL+=1
  echo %KEY% FAILED-TO-RUN>>"%HERE%verify-results.txt"
  goto :eof
)
set "STATUS=IDENTICAL"
set "DIFFS="
set "NFILES=0"
for /f "usebackq tokens=1,2,3" %%h in ("%HERE%cases\reference-hashes.txt") do (
  if "%%h"=="%KEY%" (
    set /a NFILES+=1
    set "NEW=%WORK%\%SUB%\%BASE%_new%%~xi"
    set "H=missing"
    if exist "!NEW!" (
      "%HERE%ATBRunner.exe" --strip-hash "!NEW!" --outfile "%WORK%\hash.tmp"
      set /p LINE=<"%WORK%\hash.tmp"
      for /f "tokens=1" %%x in ("!LINE!") do set "H=%%x"
    )
    if /i not "!H!"=="%%j" (
      set "STATUS=DIFFERS"
      set "DIFFS=!DIFFS! %%~xi"
    )
  )
)
echo %KEY%: %STATUS%  (%NFILES% files checked%DIFFS%)
echo %KEY% %STATUS%%DIFFS%>>"%HERE%verify-results.txt"
if "%STATUS%"=="IDENTICAL" (set /a NID+=1) else (set /a NDF+=1)
goto :eof
