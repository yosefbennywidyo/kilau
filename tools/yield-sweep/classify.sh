#!/bin/bash
# K-029/K-030-family sweep report. Usage: classify.sh <sweepdir>
# <sweepdir> must already contain gen.rb's probes + index.txt, and each
# probe's run.sh output as "<probe>.rb <OUTCOME>" lines in results.txt
# (produced by: for f in p*.rb; do run.sh "$f"; done >> results.txt).
# Joins outcome -> method name/args and prints one table per outcome, so a
# human can triage real same-shape-mismatch bugs apart from expected noise
# (metaprogramming methods, Enumerator#inspect differences, deliberate
# element-kind rejections like push/concat/unshift with a mixed argument).
set -euo pipefail
dir="$1"
cd "$dir"
paste <(cut -d' ' -f1 results.txt | sed -E 's/^(p[0-9]+)_.*/\1/') \
      <(awk '{print $2}' results.txt) > mapped.txt
join -t$'\t' <(sort mapped.txt) <(sort index.txt) > joined.txt
for outcome in CC_FAIL MISMATCH RUBY_ERR OK; do
  echo "=== $outcome ($(awk -F'\t' -v o="$outcome" '$2==o' joined.txt | wc -l)) ==="
  awk -F'\t' -v o="$outcome" '$2==o{print $3, $4}' joined.txt | sort
  echo
done
echo "Per-probe files are <probedir>/<pNNNN_name>.{rb,ruby.out,cc.log,spn.out} -- inspect by hand."
