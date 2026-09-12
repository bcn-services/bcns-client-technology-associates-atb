# Assembles the client package folder and its reference hashes (runs on the Windows runner after build.bat).
#   package\ATBRunner.exe ATBV3.exe README.txt verify.bat volatile.txt cases\<case>\<base>.LIN cases\cases.txt cases\reference-hashes.txt
param([string]$Repo = (Resolve-Path "$PSScriptRoot\..\.."), [string]$Out = "$env:RUNNER_TEMP\package")
$ErrorActionPreference = "Stop"
$fe = "$Repo\frontend"
New-Item -ItemType Directory -Force "$Out\cases" | Out-Null
Copy-Item "$fe\bin\ATBRunner.exe", "$fe\bin\ATBV3.exe", "$fe\package\README.txt", "$fe\package\verify.bat", "$fe\package\volatile.txt" $Out -Force
$cases = @(); $hashes = @()
foreach ($d in (Get-ChildItem "$Repo\cases" -Directory | Sort-Object Name)) {
  New-Item -ItemType Directory -Force "$Out\cases\$($d.Name)" | Out-Null
  Copy-Item "$($d.FullName)\*.LIN" "$Out\cases\$($d.Name)\" -Force
  $runs = if ($d.Name -eq "2638") { @(@("2638_Start_135_", "2638_Start_135_"), @("2638_135_Restart_2a", "2638_135_Restart_2a")) } else { @(,@($d.Name, (Get-ChildItem $d.FullName -Filter *.LIN | Select-Object -First 1).BaseName)) }
  foreach ($r in $runs) {
    $key, $base = $r
    $cases += "$key $($d.Name) $base $($d.Name)"
    $files = Get-ChildItem $d.FullName -File | Where-Object { $_.BaseName -eq $base -and $_.Extension -notmatch '^\.(LIN|lin)$' } | Sort-Object Name
    foreach ($f in $files) {
      Remove-Item "$Out\h.tmp" -ErrorAction SilentlyContinue
      # ATBRunner is a windows-subsystem exe: PowerShell's & would not wait for it, Start-Process -Wait does
      Start-Process -FilePath "$Out\ATBRunner.exe" -ArgumentList @("--strip-hash", "`"$($f.FullName)`"", "--volatile", "`"$Out\volatile.txt`"", "--outfile", "`"$Out\h.tmp`"") -Wait -NoNewWindow
      $line = (Get-Content "$Out\h.tmp" | Select-Object -First 1)
      if (-not $line -or $line.Split(' ')[0].Length -ne 64) { throw "strip-hash failed for $($f.FullName): [$line]" }
      $hashes += "$key $($f.Name) $($line.Split(' ')[0])"
    }
  }
}
Remove-Item "$Out\h.tmp" -ErrorAction SilentlyContinue
$cases -join "`r`n" | Set-Content "$Out\cases\cases.txt" -Encoding ASCII
$hashes -join "`r`n" | Set-Content "$Out\cases\reference-hashes.txt" -Encoding ASCII
"package: $($cases.Count) runs, $($hashes.Count) reference files"
Get-ChildItem $Out -Recurse -File | ForEach-Object { "{0,10} {1}" -f $_.Length, $_.FullName.Substring($Out.Length + 1) }
