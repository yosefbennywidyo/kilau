#!/bin/bash
# A/B of S3 (GET /posts, 100 rows) between two Kilau trees built with the
# same compiler. Interleaved: for each concurrency and rep, old then new.
# Usage: ab.sh <old-tree> <new-tree> <outdir> <bin> [seconds] [reps]
set -u
OLD=$1; NEW=$2; OUT=$3; BIN=$4; SECS=${5:-20}; REPS=${6:-3}
OHA=$(mise which oha)
PORT=5197
mkdir -p "$OUT"
echo "power=$(pmset -g batt | head -1) lowpowermode=$(pmset -g | awk '/lowpowermode/ {print $2}')" > "$OUT/meta.txt"
APP_PID=""
stop() { [ -n "$APP_PID" ] && kill "$APP_PID" 2>/dev/null && wait "$APP_PID" 2>/dev/null; APP_PID=""; }
trap stop EXIT
seed() { # tree dbpath
  rm -f "$2" "$2-wal" "$2-shm"
  (cd "$1/examples/blog" && KILAU_ENV=production KILAU_DATABASE_PATH="$2" ./build/bin/blog db migrate) > /dev/null || return 1
  sqlite3 "$2" < "$1/bench/seed.sql"
}
run() { # label tree conc rep
  local db="/tmp/kilau-ab-$1.sqlite3"
  seed "$2" "$db" || { echo "FAIL seed $1"; exit 1; }
  (cd "$2/examples/blog" && exec env KILAU_ENV=production KILAU_DATABASE_PATH="$db" KILAU_SERVER_PORT="$PORT" \
    KILAU_DATABASE_POOL=5 KILAU_LOGGER_REQUESTS=false SPINEL_WORKERS="$(sysctl -n hw.ncpu)" "./build/bin/$BIN" start) > "$OUT/$1.log" 2>&1 &
  APP_PID=$!
  for _ in $(seq 500); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/_ping")" = 200 ] && break
    sleep 0.01
  done
  bytes=$(curl -s "http://127.0.0.1:$PORT/posts" | wc -c | tr -d ' ')
  "$OHA" --no-tui --output-format json --redirect 0 -z 3s -c "$3" "http://127.0.0.1:$PORT${URLPATH:-/posts}" > /dev/null 2>&1
  "$OHA" --no-tui --output-format json --redirect 0 -z "${SECS}s" -c "$3" "http://127.0.0.1:$PORT${URLPATH:-/posts}" > "$OUT/$1-c$3-r$4.json" 2>/dev/null
  stop
  ruby -rjson -e 'd=JSON.parse(File.read(ARGV[0])); s=d["summary"]; codes=d["statusCodeDistribution"]; printf("%s c%s r%s rps=%d p99=%.2fms codes=%s bytes=%s\n", ARGV[1], ARGV[2], ARGV[3], s["requestsPerSec"], d["latencyPercentiles"]["p99"]*1000, codes.inspect, ARGV[4])' "$OUT/$1-c$3-r$4.json" "$1" "$3" "$4" "$bytes"
}
for c in ${CONCS:-1 16}; do
  for r in $(seq "$REPS"); do
    run old "$OLD" "$c" "$r"; sleep 5
    run new "$NEW" "$c" "$r"; sleep 5
  done
done
echo AB_DONE
