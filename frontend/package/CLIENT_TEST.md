# ATB Runner: what to test on your Windows 10 machine (Tier B)

This is the client-side check. Everything below takes about 15 minutes, most of it waiting.

## What you received
One folder called `ATBRunner`. Inside: `ATBRunner.exe` (the new front end), `ATBV3.exe` (your
original solver, unchanged), `verify.bat`, `README.txt`, and a `cases` folder with your 12
reference input decks.

## Step 1: put the folder somewhere short
Copy the whole folder to `C:\ATBRunner`. The old solver cannot handle long folder names.
Do not put it under Documents or on a network drive.

## Step 2: run the automatic check
Double-click `verify.bat`. A black window opens and runs your 12 reference cases one after
another. The solver's own window will pop up for each case and close by itself. Do not type in
it and do not click in it. When it is done the window shows one line per case ending in
**IDENTICAL** or **DIFFERS**, then a summary line such as:

```
===== RESULT: 12 IDENTICAL, 0 DIFFERS, 0 FAILED TO RUN  (of 12 runs)
```

The same lines are saved in `verify-results.txt` inside the folder.

* All 12 IDENTICAL: the front end reproduces your reference results on your machine. Done.
* Any DIFFERS: send us `verify-results.txt` and the folder `C:\Users\Public\ATBRun\verify`
  (paste that path into the File Explorer address bar). Then tell us whether this is the same
  computer the reference outputs were made on in 2022. The old solver's arithmetic depends on
  the CPU: in our tests the same untouched `ATBV3.exe` gave different late-time results on an
  AMD and on an Intel machine, while the front end itself changed nothing. If this is the 2022
  machine, DIFFERS is a real finding and we will show you the exact lines. If it is a newer
  machine, DIFFERS is expected on a few cases and we will still show you the lines.
* Any FAILED TO RUN: same, send us those two things.

## Step 3: run one case yourself
1. Double-click `ATBRunner.exe`.
2. Click **Browse...** and pick `cases\2589\2589_10.LIN`.
3. Leave the output name as `2589_10_new` and click **Run**.
4. Watch the status line: it says running with the elapsed seconds, then finished with the
   solver exit code. Exit code 1 is the solver's normal ending.
5. Click **Open folder**. You should see `2589_10_new.aou`, `.t21` and the other output files.

## Step 4: tell us
Reply with: the summary line from step 2, whether step 3 worked, and your Windows version
(Settings, System, About). That is all we need to close the Tier B check.

## What this does not test
3D animation, graphs, deck editing and the saved-case library are out of scope. The front end
only runs the solver and shows the files it writes.
