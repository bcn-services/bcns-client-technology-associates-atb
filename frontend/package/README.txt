ATB Runner  -  runs the original ATBV3.exe (ATB Version 3.1, 2005) on Windows 10/11 64-bit
==========================================================================================

WHAT THIS IS
  ATBRunner.exe is a small front end. It starts your ORIGINAL, unmodified ATBV3.exe,
  answers its five start-up questions for you, dismisses its "Exit Window?" prompt when
  the run ends, and shows you the output files. The solver itself is untouched: the
  ATBV3.exe in this folder is byte-for-byte the one in your ATBv3-1 folder, and
  ATBRunner checks its SHA-256 fingerprint every time before it runs it. If the
  fingerprint ever differs, ATBRunner refuses to run.

  ATBRunner never edits an input deck and never changes anything in the solver.

FILES
  ATBRunner.exe         the front end (needs .NET Framework 4.8, built into Windows 10/11)
  ATBV3.exe             your original solver, SHA-256
                        291c33c8cc3af4241de41508c997c58e9d700303b6ef002cc1f478707f55a65c
  verify.bat            re-runs the 12 reference cases and reports IDENTICAL / DIFFERS
  volatile.txt          the lines verify.bat ignores (run date/time/path stamps)
  cases\                the 12 reference input decks and their reference hashes
  README.txt            this file

RUNNING A CASE (GUI)
  1. Double-click ATBRunner.exe.
  2. Browse... and pick a .LIN input deck.
  3. Output name defaults to <deck>_new. Change it if you like (max 32 characters).
  4. Run. The status line shows running / elapsed / finished / solver exit code.
     The solver's own window opens while it runs; leave it alone.
  5. When finished, outputs (.aou, .t21 ... , .sa1) are listed. "Open folder" shows them.
     Double-click an output to open it in Notepad.
  Only one run at a time is allowed.

RUNNING A CASE (COMMAND LINE / BATCH)
  ATBRunner.exe --lin C:\path\to\deck.LIN --out deck_new --dir C:\path\to
  Exit code 0 = finished normally (the solver's own normal exit code is 1),
  1 = the run failed, 3 = ATBV3.exe fingerprint mismatch, 4 = another run in progress.
  A log is written next to the outputs when --log FILE is given.

WORK FOLDER RULE
  The 2005 solver stores its working folder in an 80-character field. Keep the folder
  containing the deck short (under 50 characters, no spaces). If the folder is long,
  the GUI runs the case in %LOCALAPPDATA%\ATBRun\<deck> and copies the outputs back.

VERIFYING (verify.bat)
  Double-click verify.bat (or run it from a command prompt). It runs all 12 reference
  cases (about 5-10 minutes) and prints IDENTICAL or DIFFERS for each one, then a
  summary line. Results are also appended to verify-results.txt next to it.
  DIFFERS on a case means a numeric result differs from the reference output that was
  produced on the original machine; the logs under %LOCALAPPDATA%\ATBRun\verify say which
  file. Differences can come from the CPU/floating-point hardware, not only from the
  front end, so a DIFFERS result should be sent back with verify-results.txt attached.

WHAT ATBRUNNER DOES TO ANSWER THE PROMPTS
  It posts the keystrokes ("y", Enter, "l", input name, output name) to the solver's
  own window, the same characters you would type. See FIDELITY.md in the source
  repository for the evidence that this changes nothing in the results.
