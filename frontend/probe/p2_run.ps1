# Push #2: (1) hash-tamper refusal, (2) rung 1 = the ATB 3I handoff for the ATB3I build (exe B) now that
# C:\ATBFIG.SYS is understood, (3) the client package + verify.bat rehearsal (gate 5), (4) all 12 cases
# through exe B (reference-producer check) and through SendInput on exe A (independent second input
# method for gate 3). The P1 ladder itself ran in push #1 (p1_ladder.ps1) and is not repeated.
param([string]$Repo = (Resolve-Path "$PSScriptRoot\..\.."), [string]$Work = "$env:RUNNER_TEMP\w", [string]$Pkg = "$env:RUNNER_TEMP\package", [int]$BudgetMin = 26)
$ErrorActionPreference = "Continue"
$t0 = Get-Date
function Elapsed { [int]((Get-Date) - $t0).TotalSeconds }
function Say($s) { "[{0,5}s] {1}" -f (Elapsed), $s | Tee-Object -FilePath "$Work\probe.log" -Append }
New-Item -ItemType Directory -Force $Work | Out-Null
$RUNNER = "$Repo\frontend\bin\ATBRunner.exe"
$A = "$Repo\frontend\bin\ATBV3.exe"; $B = "$Repo\frontend\bin\ATBV3_ATB3I.exe"
Say "repo=$Repo work=$Work pkg=$Pkg"
Get-FileHash -Algorithm SHA256 $A, $B, $RUNNER | ForEach-Object { Say ("sha256 {0} {1}" -f $_.Hash.ToLower(), $_.Path) }
Say ("session: interactive={0} user={1} PUBLIC={2} LOCALAPPDATA={3}" -f [Environment]::UserInteractive, $env:USERNAME, $env:PUBLIC, $env:LOCALAPPDATA)

$CASE = "2589"; $BASE = "2589_10"
function Prep($dir) { New-Item -ItemType Directory -Force $dir | Out-Null; Copy-Item "$Repo\cases\$CASE\$BASE.LIN" "$dir\$BASE.lin" -Force }
$results = @()
function Rung($name, $exe, $dir, $outName, [string[]]$extra) {
  Prep $dir
  $log = "$Work\$name.log"; $shots = "$Work\shots\$name"
  Say "=== RUNG $name : $exe -> $dir\$outName.*  extra=[$extra]"
  $argv = @("--lin", "$dir\$BASE.lin", "--out", $outName, "--dir", $dir, "--exe", $exe, "--log", $log, "--shots", $shots, "--abort-after", "90", "--timeout", "600") + $extra
  $p = Start-Process -FilePath $RUNNER -ArgumentList ($argv | ForEach-Object { '"' + $_ + '"' }) -Wait -PassThru -NoNewWindow
  $tail = if (Test-Path $log) { (Get-Content $log | Select-String "RESULT|error=|handoff|frame window|no visible|dialog:" | Select-Object -Last 6) -join " | " } else { "(no log)" }
  Say "--- $name runner-exit=$($p.ExitCode) $tail"
  Get-ChildItem $dir | ForEach-Object { Say ("    {0,10} {1}" -f $_.Length, $_.Name) }
  $ok = ($p.ExitCode -eq 0) -and (Test-Path "$dir\$outName.t21") -and ((Get-Item "$dir\$outName.t21").Length -gt 0)
  $script:results += [pscustomobject]@{ rung = $name; exe = (Split-Path $exe -Leaf); pass = $ok; runnerExit = $p.ExitCode; dir = $dir; out = $outName }
  return $ok
}

# (1) tamper test: a copy of ATBV3.exe with one byte changed must be refused (exit 3) before anything runs
try {
  $tdir = "$Work\tamper"; New-Item -ItemType Directory -Force $tdir | Out-Null
  $bytes = [IO.File]::ReadAllBytes($A); $bytes[$bytes.Length - 1] = ($bytes[$bytes.Length - 1] -bxor 1); [IO.File]::WriteAllBytes("$tdir\ATBV3.exe", $bytes)
  Prep $tdir
  $p = Start-Process -FilePath $RUNNER -ArgumentList @("--lin", "`"$tdir\$BASE.lin`"", "--out", "${BASE}_t", "--dir", "`"$tdir`"", "--exe", "`"$tdir\ATBV3.exe`"", "--log", "`"$Work\tamper.log`"") -Wait -PassThru -NoNewWindow
  Say ("tamper test: runner exit={0} (expect 3), outputs={1}" -f $p.ExitCode, (Get-ChildItem $tdir -Filter "${BASE}_t.*").Count)
  Remove-Item "$tdir\ATBV3.exe" -Force
} catch { Say "tamper test failed to set up: $_" }

# (2) rung 1: ATB 3I handoff, exe B. r1a = exactly what ATB 3I does (System32); r1b = same files in the work dir
$sysBefore = Get-ChildItem ([Environment]::SystemDirectory) -File | Select-Object -ExpandProperty Name
$r1a = Rung "r1a-handoff-sys32-B" $B "$Work\r1a" "${BASE}_r1a" @("--feed", "handoff", "--handoff-dir", "system32")
if (Test-Path "C:\ATBFIG.SYS") { Say ("C:\ATBFIG.SYS = [{0}]" -f (([IO.File]::ReadAllText("C:\ATBFIG.SYS")) -replace "`r`n", "|")) }
Compare-Object $sysBefore (Get-ChildItem ([Environment]::SystemDirectory) -File | Select-Object -ExpandProperty Name) | ForEach-Object { Say ("    System32 new/removed: {0} {1}" -f $_.SideIndicator, $_.InputObject) }
Get-ChildItem "$env:windir\Temp" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $t0 } | ForEach-Object { Say ("    windir\Temp new: {0} {1}" -f $_.Length, $_.Name) }
Get-ChildItem "C:\" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $t0 } | ForEach-Object { Say ("    C:\ new: {0} {1}" -f $_.Length, $_.Name) }
Remove-Item ([Environment]::SystemDirectory + "\winintm.sys"), ([Environment]::SystemDirectory + "\execatb.dat") -Force -ErrorAction SilentlyContinue
$r1b = Rung "r1b-handoff-workdir-B" $B "$Work\r1b" "${BASE}_r1b" @("--feed", "handoff")
$handoffMode = if ($r1a) { @("--feed", "handoff", "--handoff-dir", "system32") } elseif ($r1b) { @("--feed", "handoff") } else { $null }
if ($handoffMode) { Rung "r1-dup-B" $B "$Work\r1dup" "${BASE}_r1d" $handoffMode | Out-Null }
Say "=== RUNG SUMMARY"; $results | ForEach-Object { Say ("  {0,-24} {1,-18} pass={2} runnerExit={3}" -f $_.rung, $_.exe, $_.pass, $_.runnerExit) }
$results | ConvertTo-Json | Set-Content "$Work\rungs.json"

# (3) gate 5 rehearsal: build the package exactly as shipped, run verify.bat from it as the client would
try {
  Say "=== PACKAGE"
  & "$Repo\frontend\probe\make_package.ps1" -Repo $Repo -Out $Pkg 2>&1 | ForEach-Object { Say "  pkg: $_" }
  Say "=== verify.bat"
  $vp = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "verify.bat > `"$Work\verify-console.txt`" 2>&1" -WorkingDirectory $Pkg -Wait -PassThru -NoNewWindow
  Say ("verify.bat exit={0}" -f $vp.ExitCode)
  Get-Content "$Work\verify-console.txt" | Where-Object { $_ -match "^\S+: (IDENTICAL|DIFFERS|FAILED)|RESULT|work:|refused" } | ForEach-Object { Say "  $_" }
  if (Test-Path "$Pkg\verify-results.txt") { Copy-Item "$Pkg\verify-results.txt" "$Work\verify-results.txt" }
  $vroot = if ($env:PUBLIC) { "$env:PUBLIC\ATBRun\verify" } else { "$env:LOCALAPPDATA\ATBRun\verify" }
  if (Test-Path $vroot) { Copy-Item $vroot "$Work\verify-work" -Recurse -Force; Say "copied $vroot -> $Work\verify-work" }
} catch { Say "package/verify failed: $_" }

# (4) all 12 cases: exe B through the handoff (does B on this CPU reproduce the references, incl. 2696?), then exe A via SendInput
function AllCases($tag, $exe, [string[]]$mode) {
  $root = "$Work\$tag"; New-Item -ItemType Directory -Force $root | Out-Null; "" | Set-Content "$root\cases.txt" -NoNewline
  $list = @()
  foreach ($d in (Get-ChildItem "$Repo\cases" -Directory | Sort-Object Name)) {
    if ($d.Name -eq "2638") { $list += ,@("2638_Start_135_", "2638", "2638_Start_135_", "2638"); $list += ,@("2638_135_Restart_2a", "2638", "2638_135_Restart_2a", "2638"); continue }
    $lin = Get-ChildItem $d.FullName -Filter *.LIN | Select-Object -First 1
    $list += ,@($d.Name, $d.Name, $lin.BaseName, $d.Name)
  }
  foreach ($c in $list) {
    if ((Elapsed) -gt $BudgetMin * 60) { Say "budget exhausted before $($c[0]) in $tag"; break }
    $key, $cd, $base, $sub = $c; $w = "$root\$sub"; New-Item -ItemType Directory -Force $w | Out-Null
    Copy-Item "$Repo\cases\$cd\$base.LIN" "$w\$base.lin" -Force
    $t1 = Get-Date
    $argv = @("--lin", "$w\$base.lin", "--out", "${base}_new", "--dir", $w, "--exe", $exe, "--log", "$w\$base.runner.log", "--abort-after", "90", "--timeout", "900") + $mode
    $p = Start-Process -FilePath $RUNNER -ArgumentList ($argv | ForEach-Object { '"' + $_ + '"' }) -Wait -PassThru -NoNewWindow
    $secs = [int]((Get-Date) - $t1).TotalSeconds
    $m = Select-String -Path "$w\$base.runner.log" -Pattern "process exited code=(-?\d+)" | Select-Object -Last 1
    $rc = if ($m) { $m.Matches[0].Groups[1].Value } else { "none" }
    "$key $cd $base $sub $rc $secs" | Add-Content "$root\cases.txt"
    $t21 = if (Test-Path "$w\${base}_new.t21") { (Get-Item "$w\${base}_new.t21").Length } else { 0 }
    Say ("  {0}: {1,-22} rc={2} runner={3} {4}s t21={5}B" -f $tag, $key, $rc, $p.ExitCode, $secs, $t21)
  }
}
if ($handoffMode) { AllCases "all-handoff-B" $B $handoffMode } else { Say "exe B handoff did not pass on 2589; no all-12 for B" }
if ((Elapsed) -lt ($BudgetMin - 5) * 60) { AllCases "all-sendinput-A" $A @("--feed", "sendinput") } else { Say "no time for all-sendinput-A" }
Remove-Item "C:\ATBFIG.SYS" -Force -ErrorAction SilentlyContinue
Say "DONE"
