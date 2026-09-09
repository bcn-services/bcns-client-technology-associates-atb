#!/bin/bash
# Run every client case through the solver and leave outputs under $WORK.
#   ATB       solver binary (default: <repo>/src/atb)
#   EXAMPLES  case directories (default: <repo>/cases)
#   WORK      scratch dir; keep the path SHORT (< ~50 chars) — the solver stores
#             the working directory in an 80-char Fortran string.
# Writes $WORK/cases.txt: "<key> <casedir> <basename> <subdir> <rc> <seconds>" per run,
# consumed by cmp.py / grow.py / report.py.
set -u
here=$(cd "$(dirname "$0")" && pwd); root=$(cd "$here/.." && pwd)
ATB=${ATB:-$root/src/atb}; EXAMPLES=${EXAMPLES:-$root/cases}; WORK=${WORK:-$here/out}
mkdir -p "$WORK"; : > "$WORK/cases.txt"

run_one() {  # run_one <key> <casedir> <basename> [<subdir>]  (outputs land in $WORK/<subdir>, default <key>)
  local key=$1 d=$2 base=$3 sub=${4:-$1} w=$WORK/${4:-$1} rc t0
  mkdir -p "$w"; cp "$EXAMPLES/$d/$base.LIN" "$w/$base.lin"
  # prompts: y=accept terms, blank=default workdir (cwd), l=.lin input,
  #          input name, output name
  t0=$(date +%s)
  ( cd "$w" && rm -f atb_parms.mem && printf 'y\n\nl\n%s\n%s_new\n' "$base" "$base" | "$ATB" > "$base.term.log" 2>&1 )
  rc=$?
  echo "$key $d $base $sub $rc $(( $(date +%s) - t0 ))" >> "$WORK/cases.txt"
  echo "== $key rc=$rc $(( $(date +%s) - t0 ))s  $(grep -c . "$w/${base}_new.aou" 2>/dev/null) aou lines; ref $(grep -c . "$EXAMPLES/$d/$base.aou")"
  grep -E 'Step +[0-9]+ of' "$w/$base.term.log" | tail -1
}

for dpath in "$EXAMPLES"/*/; do
  d=$(basename "$dpath")
  if [ "$d" = 2638 ]; then
    # Restart pair: 2638_Start_135_ then 2638_135_Restart_2a, run in that order in
    # one directory (as the client did). The solver has no restart-file mechanism;
    # the second .LIN carries its own initial conditions, so step 2 reads nothing
    # step 1 wrote.  Each step is compared against its own reference outputs.
    run_one 2638_Start_135_     2638 2638_Start_135_     2638
    run_one 2638_135_Restart_2a 2638 2638_135_Restart_2a 2638
    continue
  fi
  lin=$(ls "$dpath"/*.LIN | head -1); base=$(basename "$lin" .LIN)
  run_one "$d" "$d" "$base"
done
