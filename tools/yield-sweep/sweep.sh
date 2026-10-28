#!/bin/bash
# One-shot K-029/K-030-family yield-receiver sweep. Usage:
#   SPINEL=/path/to/spinel tools/yield-sweep/sweep.sh <outdir>
# Generates probes (gen.rb), runs each through CRuby + spinel (run.sh), and
# prints the classify.sh report. SPINEL defaults to spinel on PATH.
set -euo pipefail
dir="$1"
mkdir -p "$dir"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ruby "$script_dir/gen.rb" "$dir"
cd "$dir"
: > results.txt
for f in p*.rb; do
  "$script_dir/run.sh" "$f" >> results.txt
done
"$script_dir/classify.sh" "$dir"
