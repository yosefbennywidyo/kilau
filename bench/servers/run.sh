#!/bin/bash
# The Kilau blog behind different HTTP servers, in one session (see
# README.md here). Per cell: a fresh copy of the seed database, a fresh
# server, a warm-up, then REPS runs of oha; the apps are the innermost
# loop so every app of a cell meets the same machine state.
#
#   bench/servers/run.sh                     about 50 minutes
#   QUICK=1 bench/servers/run.sh             a smoke run
#
# Knobs: APPS, CELLS ("scenario:concurrency ..."), REPS, WARMUP, DURATION,
# COOLDOWN, OUT.
set -u
source "$(dirname "$0")/../lib.sh"
HERE="$BENCH/servers"
trap stop_app EXIT
trap 'exit 130' INT TERM
APPS=${APPS:-"kilau-spinel kilau-cruby kilau-puma kilau-pitchfork kilau-falcon rails-puma"}
CELLS=${CELLS:-"s1:1 s1:16 s1:64 s3:1 s3:16 s3:64 s2:16 s4:16"}
if [ "${QUICK:-0}" = 1 ]; then REPS=${REPS:-1}; WARMUP=${WARMUP:-1}; DURATION=${DURATION:-3}; COOLDOWN=${COOLDOWN:-0}
else REPS=${REPS:-3}; WARMUP=${WARMUP:-5}; DURATION=${DURATION:-15}; COOLDOWN=${COOLDOWN:-5}; fi
OHA=${OHA:-$(mise which oha)}
OUT=${OUT:-$BENCH/results/$(date +%Y%m%d-%H%M)-servers}
PORT=5194
SQLITE_LIB=${KILAU_SQLITE_LIB:-$(cd "$BENCH/../framework" && spin flags 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "-I" && $(i + 1) ~ /sqlite/) print $(i + 1)}')}
mkdir -p "$OUT"
make_seed_db || { echo "FAIL: cannot build the seed database"; exit 1; }

{
  echo "date=$(date '+%Y-%m-%d %H:%M %Z')"
  echo "kilau_sha=$(git -C "$BENCH/.." rev-parse --short HEAD)"
  echo "machine=$(sysctl -n hw.model) $(sysctl -n machdep.cpu.brand_string) cores=$CORES"
  echo "power=$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/") lowpowermode=$(pmset -g | awk '/lowpowermode/ {print $2}')"
  echo "spinel=$(spinel --version 2>&1 | head -1)"
  echo "ruby=$(ruby -v) (CRuby apps run with --yjit)"
  (cd "$HERE" && bundle list 2>/dev/null | grep -E ' (rack|puma|pitchfork|falcon|sqlite3) ' | tr -s ' ' | tr '\n' ';'); echo
  echo "reps=$REPS warmup=$WARMUP duration=$DURATION cooldown=$COOLDOWN pool=$POOL workers=$CORES"
} > "$OUT/meta.txt"

# start_server APP DB LOG: sets APP_PID.
start_server() {
  local app=$1 db=$2 log=$3
  case $app in
    kilau-spinel) start_app kilau-routes "$PORT" "$db" "$log" ;;
    rails-puma) start_app rails "$PORT" "$db" "$log" ;;
    kilau-cruby)
      (cd "$BLOG" && exec env KILAU_ENV=production KILAU_DATABASE_PATH="$db" KILAU_SERVER_PORT="$PORT" \
        KILAU_DATABASE_POOL="$POOL" KILAU_LOGGER_REQUESTS=false BUNDLE_GEMFILE="$HERE/Gemfile" \
        bundle exec ruby --yjit -I "$SQLITE_LIB" -I "$BENCH/../framework" bin/blog_routes.rb start) > "$log" 2>&1 &
      APP_PID=$! ;;
    kilau-puma|kilau-pitchfork|kilau-falcon)
      (cd "$HERE" && export KILAU_ENV=production KILAU_DATABASE_PATH="$db" KILAU_DATABASE_POOL="$POOL" \
        KILAU_LOGGER_REQUESTS=false KILAU_SQLITE_LIB="$SQLITE_LIB" PORT="$PORT" WEB_CONCURRENCY="$CORES" RUBYOPT=--yjit
        case $app in
          kilau-puma) exec bundle exec puma -C puma.rb config.ru ;;
          kilau-pitchfork) exec bundle exec pitchfork -c pitchfork.rb -E production config.ru ;;
          kilau-falcon) exec bundle exec falcon serve --bind "http://127.0.0.1:$PORT" --count "$CORES" -c config.ru ;;
        esac) > "$log" 2>&1 &
      APP_PID=$! ;;
    *) echo "unknown app $app" >&2; return 1 ;;
  esac
}

url_of() {
  case $1 in
    s1) echo "http://127.0.0.1:$PORT/_ping" ;;
    s2) echo "http://127.0.0.1:$PORT/posts/42" ;;
    s3|s4) echo "http://127.0.0.1:$PORT/posts" ;;
  esac
}

oha_run() {
  local extra=()
  [ "$1" = s4 ] && extra=(-m POST -T application/x-www-form-urlencoded -d 'post%5Btitle%5D=Bench+post&post%5Bcontent%5D=Isi')
  "$OHA" --no-tui --output-format json --redirect 0 -z "${3}s" -c "$2" ${extra[@]+"${extra[@]}"} "$(url_of "$1")" > "$4" 2> "$4.err"
}

for cellspec in $CELLS; do
  s=${cellspec%%:*}; c=${cellspec##*:}
  for app in $APPS; do
    sleep "$COOLDOWN"
    cell="$app-$s-c$c"
    db="/tmp/kilau-servers-cell.sqlite3"
    fresh_db "$db"
    start_server "$app" "$db" "$OUT/$cell.log"
    if ! ms=$(wait_ready "$PORT"); then echo "FAIL $cell: app did not start"; tail -5 "$OUT/$cell.log"; stop_app; exit 1; fi
    echo "$ms" > "$OUT/$cell.startup_ms"
    # The body every app must agree on (GET scenarios only).
    [ "$s" != s4 ] && curl -s "$(url_of "$s")" | md5 -q > "$OUT/$cell.md5"
    ( while kill -0 "$APP_PID" 2>/dev/null; do tree_rss; sleep 0.5; done ) > "$OUT/$cell.rss" &
    sampler=$!
    oha_run "$s" "$c" "$WARMUP" "$OUT/$cell.warmup.json"
    for r in $(seq "$REPS"); do oha_run "$s" "$c" "$DURATION" "$OUT/$cell.r$r.json"; done
    stop_app
    pkill -f "falcon serve --bind http://127.0.0.1:$PORT" 2>/dev/null
    wait "$sampler" 2>/dev/null
    echo "done $cell startup=${ms}ms peak_rss=$(sort -n "$OUT/$cell.rss" | tail -1)KB"
  done
done
echo "results in $OUT"
