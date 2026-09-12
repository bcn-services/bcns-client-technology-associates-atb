@echo off
rem Builds ATBRunner.exe with the C# compiler that ships inside .NET Framework 4.x (no SDK, no NuGet).
rem Output: frontend\bin\ATBRunner.exe
setlocal
set HERE=%~dp0
set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe
if not exist "%CSC%" echo csc.exe not found at %CSC% && exit /b 1
if not exist "%HERE%bin" mkdir "%HERE%bin"
"%CSC%" /nologo /target:winexe /platform:x86 /optimize+ /out:"%HERE%bin\ATBRunner.exe" ^
  /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll ^
  "%HERE%ATBRunner\*.cs"
if errorlevel 1 exit /b 1
echo built %HERE%bin\ATBRunner.exe
