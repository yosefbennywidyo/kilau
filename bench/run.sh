#!/bin/bash
# The benchmark session (spec §6.2). For every app × scenario × concurrency
# cell: a fresh copy of the seed database, a fresh app process (its time
# to first 200 is recorded), one warm-up run, then REPS measured runs of
# oha, each saved as JSON, while the app's peak RSS is sampled.
#
#   bench/run.sh                 the full session (about 75 minutes)
#   QUICK=1 bench/run.sh         1 s warm-up, 3 s runs, 1 rep: a smoke test
#
# Knobs: APPS, SCENARIOS, CONCURRENCY, REPS, WARMUP, DURATION (seconds),
# OUT (results directory). Run bench/check_bodies.sh first; this script
# runs it and stops if the apps disagree.
set -u
source "$(dirname "$0")/lib.sh"
APPS=${APPS:-"kilau kilau-routes rails"}
SCENARIOS=${SCENARIOS:-"s1 s2 s3 s4"}
CONCURRENCY=${CONCURRENCY:-"1 16 64"}
if [ "${QUICK:-0}" = 1 ]; then REPS=${REPS:-1}; WARMUP=${WARMUP:-1}; DURATION=${DURATION:-3}
else REPS=${REPS:-3}; WARMUP=${WARMUP:-10}; DURATION=${DURATION:-30}; fi
OHA=${OHA:-$(mise which oha)}
OUT=${OUT:-$BENCH/results/$(date +%Y%m%d-%H%M)}
PORT=5198
mkdir -p "$OUT"

"$BENCH/check_bodies.sh" > "$OUT/check_bodies.txt" 2>&1 || { cat "$OUT/check_bodies.txt"; echo "bodies differ: no benchmark"; exit 1; }

{
  echo "date=$(date '+%Y-%m-%d %H:%M %Z')"
  echo "kilau_sha=$(git -C "$BENCH/.." rev-parse --short HEAD)"
  echo "machine=$(sysctl -n hw.model) $(sysctl -n machdep.cpu.brand_string) cores=$CORES mem=$(( $(sysctl -n hw.memsize) / 1073741824 ))GB"
  echo "os=$(sw_vers -productName) $(sw_vers -productVersion)"
  echo "spinel=$(spinel --version 2>&1 | head -1)"
  echo "ruby=$(ruby -v)"
  echo "rails=$(cd "$BENCH/rails_blog" && bundle exec ruby -e 'require "rails"; print Rails.version')"
  echo "puma=$(cd "$BENCH/rails_blog" && bundle exec puma --version)"
  echo "oha=$($OHA --version)"
  echo "reps=$REPS"
  echo "warmup=$WARMUP"
  echo "duration=$DURATION"
  echo "pool=$POOL"
  echo "artifact_kilau_bytes=$(stat -f %z "$BLOG/build/bin/blog")"
  echo "artifact_kilau_routes_bytes=$(stat -f %z "$BLOG/build/bin/blog_routes")"
  echo "artifact_rails_kb=$(du -sk -I log -I tmp "$BENCH/rails_blog" | cut -f1)"
} > "$OUT/meta.txt"

url_of() {
  case $1 in
    s1) echo "http://127.0.0.1:$PORT/_ping" ;;
    s2) echo "http://127.0.0.1:$PORT/posts/42" ;;
    s3) echo "http://127.0.0.1:$PORT/posts" ;;
    s4) echo "http://127.0.0.1:$PORT/posts" ;;
  esac
}

# oha_run SCENARIO CONC SECONDS OUTFILE
oha_run() {
  # ${extra[@]+...}: macOS /bin/bash 3.2 calls an empty array unbound
  # under set -u, which kills the script silently.
  local extra=()
  [ "$1" = s4 ] && extra=(-m POST -T application/x-www-form-urlencoded -d 'post%5Btitle%5D=Bench+post&post%5Bcontent%5D=Isi')
  "$OHA" --no-tui --output-format json --redirect 0 -z "${3}s" -c "$2" ${extra[@]+"${extra[@]}"} "$(url_of "$1")" > "$4" 2> "$4.err"
}

for app in $APPS; do
  for s in $SCENARIOS; do
    for c in $CONCURRENCY; do
      cell="$app-$s-c$c"
      db="/tmp/kilau-bench-cell.sqlite3"
      fresh_db "$db"
      start_app "$app" "$PORT" "$db" "$OUT/$cell.log"
      if ! ms=$(wait_ready "$PORT"); then echo "FAIL $cell: app did not start"; stop_app; exit 1; fi
      echo "$ms" > "$OUT/$cell.startup_ms"
      ( while kill -0 "$APP_PID" 2>/dev/null; do tree_rss; sleep 0.5; done ) > "$OUT/$cell.rss" &
      sampler=$!
      oha_run "$s" "$c" "$WARMUP" "$OUT/$cell.warmup.json"
      for r in $(seq "$REPS"); do
        oha_run "$s" "$c" "$DURATION" "$OUT/$cell.r$r.json"
      done
      stop_app
      wait "$sampler" 2>/dev/null
      echo "done $cell startup=${ms}ms peak_rss=$(sort -n "$OUT/$cell.rss" | tail -1)KB"
    done
  done
done
echo "results in $OUT"
