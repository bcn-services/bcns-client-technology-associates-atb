#!/bin/bash
# Build the ATB solver with gfortran.
#   cd src && bash ../build.sh            # native build, output ./atb
# Environment overrides:
#   GF        compiler (default: gfortran on PATH)
#   TARGET    "win32" -> 32-bit x86, x87 FPU, fully static  (client deliverable)
#             "win64" -> 64-bit x86-64, static (comparison only, not shipped)
#             unset   -> native build for this machine
#   OUT       output file name (default: atb, or atb-win32.exe / atb-win64.exe)
set -u
GF=${GF:-gfortran}
# Fixed-form 72 columns is mandatory (TRNPOS.FOR has junk past col 72).
# -finit-local-zero -fno-automatic mimic Compaq zero-init/static locals; without
# them the matrix is singular at step 0.  -O2 stays; -ffp-contract=off did not help.
FL="-c -ffixed-form -ffixed-line-length-72 -std=legacy -fno-range-check -O2 -w -finit-local-zero -fno-automatic"
LD=""
case "${TARGET:-}" in
  win32) FL="$FL -m32 -mfpmath=387"; LD="-m32 -static"; OUT=${OUT:-atb-win32.exe} ;;
  win64) LD="-static"; OUT=${OUT:-atb-win64.exe} ;;
  "")    OUT=${OUT:-atb} ;;
  *) echo "unknown TARGET=$TARGET"; exit 2 ;;
esac
rm -f *.o *.mod "$OUT"
for f in module_standard.for module_water.for module_flexible.for; do $GF $FL $f || echo "MODFAIL $f"; done
fail=0
for f in *.for *.FOR; do case $f in module_*) continue;; esac
  if ! $GF $FL $f 2>err.txt; then fail=$((fail+1)); echo "=== FAIL $f"; grep -B3 "Error" err.txt | head -8; fi
done
echo "FAILED: $fail"
[ $fail -eq 0 ] || exit 1
$GF $LD -o "$OUT" *.o || { echo "LINK FAILED"; exit 1; }
ls -la "$OUT" && file "$OUT"
