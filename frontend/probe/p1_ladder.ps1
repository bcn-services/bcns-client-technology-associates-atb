# P1 input ladder + P3 full-case runs for the ORIGINAL ATBV3.exe on a Windows runner.
# Everything lands under $WORK (short path). Never modifies the solver binaries.
param([string]$Repo = (Resolve-Path "$PSScriptRoot\..\.."), [string]$Work = "$env:RUNNER_TEMP\w", [int]$BudgetMin = 26)
$ErrorActionPreference = "Continue"
$t0 = Get-Date
function Elapsed { [int]((Get-Date) - $t0).TotalSeconds }
function Say($s) { "[{0,5}s] {1}" -f (Elapsed), $s | Tee-Object -FilePath "$Work\probe.log" -Append }
New-Item -ItemType Directory -Force $Work | Out-Null
$RUNNER = "$Repo\frontend\bin\ATBRunner.exe"
$A = "$Repo\frontend\bin\ATBV3.exe"; $B = "$Repo\frontend\bin\ATBV3_ATB3I.exe"
Say "repo=$Repo work=$Work (len $($Work.Length))"
Get-FileHash -Algorithm SHA256 $A, $B, $RUNNER | ForEach-Object { Say ("sha256 {0} {1}" -f $_.Hash.ToLower(), $_.Path) }
Say ("session: interactive={0} user={1} sessionname={2}" -f [Environment]::UserInteractive, $env:USERNAME, $env:SESSIONNAME)
try { Add-Type -AssemblyName System.Windows.Forms; Say ("screen: {0}" -f [System.Windows.Forms.SystemInformation]::VirtualScreen) } catch { Say "screen: n/a $_" }

$CASE = "2589"; $BASE = "2589_10"
function Prep($dir) { New-Item -ItemType Directory -Force $dir | Out-Null; Copy-Item "$Repo\cases\$CASE\$BASE.LIN" "$dir\$BASE.lin" -Force }
$results = @()
function Rung($name, $exe, $dir, $outName, [string[]]$extra) {
  Prep $dir
  $log = "$Work\$name.log"; $shots = "$Work\shots\$name"
  Say "=== RUNG $name : $exe -> $dir\$outName.*  extra=[$extra]"
  $argv = @("--lin", "$dir\$BASE.lin", "--out", $outName, "--dir", $dir, "--exe", $exe, "--log", $log, "--shots", $shots, "--abort-after", "45", "--timeout", "600") + $extra
  $p = Start-Process -FilePath $RUNNER -ArgumentList ($argv | ForEach-Object { '"' + $_ + '"' }) -Wait -PassThru -NoNewWindow
  $tail = if (Test-Path $log) { (Get-Content $log | Select-String "RESULT|error=|feed target|frame window|no visible" | Select-Object -Last 4) -join " | " } else { "(no log)" }
  Say "--- $name runner-exit=$($p.ExitCode) $tail"
  Get-ChildItem $dir | ForEach-Object { Say ("    {0,10} {1}" -f $_.Length, $_.Name) }
  $ok = ($p.ExitCode -eq 0) -and (Test-Path "$dir\$outName.t21") -and ((Get-Item "$dir\$outName.t21").Length -gt 0)
  $script:results += [pscustomobject]@{ rung = $name; exe = (Split-Path $exe -Leaf); pass = $ok; runnerExit = $p.ExitCode; dir = $dir; out = $outName }
  return $ok
}

# Rung 0: does the exe start and show windows at all (both exes), no feeding
Rung "r0-enum-A" $A "$Work\r0a" "${BASE}_r0" @("--enum") | Out-Null
Rung "r0-enum-B" $B "$Work\r0b" "${BASE}_r0" @("--enum") | Out-Null

# Rung 1: what ATB 3I does (exe B only): handoff files in System32, no prompts
$sys = [Environment]::SystemDirectory
try {
  Prep "$Work\r1"
  Copy-Item "$Repo\cases\$CASE\$BASE.LIN" "$sys\winintm.sys" -Force
  [IO.File]::WriteAllText("$sys\EXECATB.DAT", "101`r`n${BASE}_r1`r`n")
  Say "rung 1: wrote $sys\winintm.sys and EXECATB.DAT (101 / ${BASE}_r1)"
  $before = Get-ChildItem $sys -File | Select-Object -ExpandProperty Name
  Rung "r1-atb3i-handoff-B" $B "$Work\r1" "${BASE}_r1" @("--feed", "none", "--abort-after", "90") | Out-Null
  $after = Get-ChildItem $sys -File | Select-Object -ExpandProperty Name
  Compare-Object $before $after | ForEach-Object { Say ("    System32 new/removed: {0} {1}" -f $_.SideIndicator, $_.InputObject) }
  Get-ChildItem $sys -Filter "${BASE}_r1.*" -ErrorAction SilentlyContinue | ForEach-Object { Say ("    in System32: {0} {1}" -f $_.Length, $_.Name); Copy-Item $_.FullName "$Work\r1\" -Force }
  Get-ChildItem (Split-Path $B) -Filter "${BASE}_r1.*" -ErrorAction SilentlyContinue | ForEach-Object { Say ("    in exe dir: {0} {1}" -f $_.Length, $_.Name); Copy-Item $_.FullName "$Work\r1\" -Force }
  Remove-Item "$sys\winintm.sys", "$sys\EXECATB.DAT" -Force -ErrorAction SilentlyContinue
} catch { Say "rung 1 failed to set up: $_" }

# Rung 2: stdin redirect (a) plain cmd redirect with a watchdog, (b) via ATBRunner redirected StandardInput
Prep "$Work\r2a"
"y`r`n`r`nl`r`n$BASE`r`n${BASE}_r2a`r`n" | Set-Content -NoNewline "$Work\r2a\answers.txt"
$cmdp = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$A`" < answers.txt > term.log 2>&1" -WorkingDirectory "$Work\r2a" -PassThru -NoNewWindow
$w = 0; while (-not $cmdp.HasExited -and $w -lt 90) { Start-Sleep 1; $w++; if ($w -eq 60 -and -not (Test-Path "$Work\r2a\${BASE}_r2a.aou")) { Say "rung 2a: no .aou after 60 s, killing"; Get-Process ATBV3 -ErrorAction SilentlyContinue | Stop-Process -Force; } }
if (-not $cmdp.HasExited) { Get-Process ATBV3 -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
Say "--- r2a cmd-redirect exit=$($cmdp.ExitCode) waited=$w s"; Get-ChildItem "$Work\r2a" | ForEach-Object { Say ("    {0,10} {1}" -f $_.Length, $_.Name) }
$r2aok = (Test-Path "$Work\r2a\${BASE}_r2a.t21") -and ((Get-Item "$Work\r2a\${BASE}_r2a.t21").Length -gt 0)
$results += [pscustomobject]@{ rung = "r2a-cmd-stdin-A"; exe = "ATBV3.exe"; pass = $r2aok; runnerExit = $cmdp.ExitCode; dir = "$Work\r2a"; out = "${BASE}_r2a" }
Rung "r2b-stdin-A" $A "$Work\r2b" "${BASE}_r2b" @("--feed", "stdin") | Out-Null
# Rung 3: pre-seeded atb_parms.mem (with stdin, the only route that needs no window)
Rung "r3-seedparms-stdin-A" $A "$Work\r3" "${BASE}_r3" @("--feed", "stdin", "--seed-parms") | Out-Null
# Rung 4: PostMessage WM_CHAR / WM_KEYDOWN to the QuickWin child
Rung "r4a-postchar-A" $A "$Work\r4a" "${BASE}_r4a" @("--feed", "postchar") | Out-Null
Rung "r4b-postkey-A" $A "$Work\r4b" "${BASE}_r4b" @("--feed", "postkey") | Out-Null
Rung "r4c-postchardeep-A" $A "$Work\r4c" "${BASE}_r4c" @("--feed", "postchardeep") | Out-Null
Rung "r4d-postchar-fg-A" $A "$Work\r4d" "${BASE}_r4d" @("--feed", "postchar", "--foreground") | Out-Null
# Rung 5: WriteConsoleInput to CONIN$
Rung "r5-conin-A" $A "$Work\r5" "${BASE}_r5" @("--feed", "conin") | Out-Null
# Rung 6: SendInput to the focused window
Rung "r6-sendinput-A" $A "$Work\r6" "${BASE}_r6" @("--feed", "sendinput") | Out-Null
# Rung 7: UI Automation focus + SendKeys
Rung "r7-uia-sendkeys-A" $A "$Work\r7" "${BASE}_r7" @("--feed", "sendkeys") | Out-Null

Say "=== LADDER SUMMARY"; $results | ForEach-Object { Say ("  {0,-24} {1,-16} pass={2} runnerExit={3}" -f $_.rung, $_.exe, $_.pass, $_.runnerExit) }
$results | ConvertTo-Json | Set-Content "$Work\ladder.json"
$passA = @($results | Where-Object { $_.pass -and $_.exe -eq "ATBV3.exe" -and $_.rung -match "^r[4-7]" })
$modeOf = @{ "r4a-postchar-A" = @("--feed","postchar"); "r4b-postkey-A" = @("--feed","postkey"); "r4c-postchardeep-A" = @("--feed","postchardeep"); "r4d-postchar-fg-A" = @("--feed","postchar","--foreground"); "r5-conin-A" = @("--feed","conin"); "r6-sendinput-A" = @("--feed","sendinput"); "r7-uia-sendkeys-A" = @("--feed","sendkeys"); "r2b-stdin-A" = @("--feed","stdin"); "r3-seedparms-stdin-A" = @("--feed","stdin","--seed-parms") }
$passAll = @($results | Where-Object { $_.pass -and $_.exe -eq "ATBV3.exe" -and $modeOf.ContainsKey($_.rung) })
if ($passAll.Count -eq 0) { Say "NO RUNG PASSED on exe A"; exit 0 }
$m1 = $passAll[0]; Say ("first passing route: {0}" -f $m1.rung)
# same route twice on 2589 -> volatile set
Rung "dup-$($m1.rung)" $A "$Work\dup" "${BASE}_dup" $modeOf[$m1.rung] | Out-Null
# exe B through the same route (does the MSI exe behave identically when prompt-driven?)
Rung "B-$($m1.rung)" $B "$Work\bsame" "${BASE}_b" $modeOf[$m1.rung] | Out-Null

# P3: all 12 runs through the first passing route, then (time permitting) through the second passing route
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
    $argv = @("--lin", "$w\$base.lin", "--out", "${base}_new", "--dir", $w, "--exe", $exe, "--log", "$w\$base.runner.log", "--abort-after", "60", "--timeout", "900") + $mode
    $p = Start-Process -FilePath $RUNNER -ArgumentList ($argv | ForEach-Object { '"' + $_ + '"' }) -Wait -PassThru -NoNewWindow
    $secs = [int]((Get-Date) - $t1).TotalSeconds
    $rc = (Select-String -Path "$w\$base.runner.log" -Pattern "process exited code=(-?\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    "$key $cd $base $sub $rc $secs" | Add-Content "$root\cases.txt"
    $t21 = if (Test-Path "$w\${base}_new.t21") { (Get-Item "$w\${base}_new.t21").Length } else { 0 }
    Say ("  {0}: {1,-22} rc={2} runner={3} {4}s t21={5}B" -f $tag, $key, $rc, $p.ExitCode, $secs, $t21)
  }
}
AllCases "all-$($m1.rung)" $A $modeOf[$m1.rung]
$m2 = $passAll | Where-Object { $_.rung -ne $m1.rung } | Select-Object -First 1
if ($m2 -and (Elapsed) -lt ($BudgetMin - 8) * 60) { Say ("second route for transparency on all cases: {0}" -f $m2.rung); AllCases "all-$($m2.rung)" $A $modeOf[$m2.rung] }
elseif ($m2) { Say ("second route {0}: only the 2589 ladder run available (time)" -f $m2.rung) }
else { Say "no second passing route" }
Say "DONE"
