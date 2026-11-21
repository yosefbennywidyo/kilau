#!/bin/bash
# What a signed session costs the blog (spec R9/R10 follow-up, slice 2).
# Standalone: not part of bench/run.sh, not a make target. Needs oha, curl,
# sqlite3 and ruby (JSON parsing only). Build the blog first:
#   make -C examples/blog all
# Usage: bench/session_cost.sh [OUTDIR]     (default bench/results/<stamp>-session)
#
#  (a) GET /posts with no cookie, with a valid session cookie, and with a
#      tampered cookie, at concurrency 1 and 16: 10 s runs, 3 repetitions,
#      the best of three by requests/s (its p50/p99 are reported).
#  (b) POST /login (valid token + credentials): 5 sequential curl logins,
#      then oha at concurrency 1 and 8 (same 10 s, best of 3).
# SKIP_GET=1 runs only (b); SPINEL_WORKERS=n sets the worker count (default 8).
# Compare rows only inside one run: the meta file records the power state.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
BLOG=$(cd "$HERE/../examples/blog" && pwd)
STAMP=$(date -u +%Y%m%d-%H%M)
OUT=${1:-$HERE/results/$STAMP-session}
DURATION=${DURATION:-10}
REPS=${REPS:-3}
WORKERS=${SPINEL_WORKERS:-8}
# One private directory per invocation: two runs at once never share the database,
# the server log, the cookie jar or the raw oha output, and cleanup removes only this one.
WORK=$(mktemp -d /tmp/kilau-session-bench.XXXXXX)
DB=$WORK/db.sqlite3
LOG=$WORK/server.log
JAR=$WORK/cookies.jar
SECRET=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
EMAIL=bench@example.com
PASSWORD=benchmark-pass-1
mkdir -p "$OUT"
RAW=$WORK/raw   # oha JSON, too big to keep
mkdir -p "$RAW"
PID=""
cleanup() {
  [ -n "$PID" ] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null
  rm -rf "${WORK:?}"
}
trap cleanup EXIT

{
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "spinel: $(spinel --version)"
  echo "build: $(cd "$BLOG" && ls -l build/bin/blog | awk '{print $5}') bytes, built with the spin default (no -O flag from spin; compiler default optimization)"
  echo "workers: $WORKERS (SPINEL_WORKERS), pool 5, WAL, KILAU_ENV=production, request log off"
  echo "oha: $(oha --version)  duration ${DURATION}s x ${REPS} reps, best by req/s"
  echo "--- power source and battery state (start)"; pmset -g batt | sed -n '1p;2s/^ -InternalBattery-[0-9]* (id=[0-9]*)//p'
  echo "--- lowpowermode"; pmset -g | grep lowpowermode
  echo "--- load average at start"; uptime | sed 's/.*averages: //'
} > "$OUT/meta.txt"

rm -f "$DB" "$DB-wal" "$DB-shm"
(cd "$BLOG" && KILAU_ENV=production KILAU_DATABASE_PATH="$DB" ./build/bin/blog db migrate) > /dev/null || exit 1
sqlite3 "$DB" < "$HERE/seed.sql"
(cd "$BLOG" && exec env KILAU_ENV=production KILAU_DATABASE_PATH="$DB" KILAU_SERVER_PORT=0 KILAU_DATABASE_POOL=5 \
  KILAU_LOGGER_REQUESTS=false KILAU_SESSION_SECRET="$SECRET" KILAU_SESSION_SECURE=false SPINEL_WORKERS="$WORKERS" ./build/bin/blog start) > "$LOG" 2>&1 &
PID=$!
for _ in $(seq 100); do grep -q "listening on" "$LOG" && break; sleep 0.1; done
PORT=$(sed -n 's/.*127\.0\.0\.1:\([0-9]*\).*/\1/p' "$LOG" | head -1)
[ -n "$PORT" ] || { echo "server did not start"; cat "$LOG"; exit 1; }
BASE="http://127.0.0.1:$PORT"

token() { curl -s -b "$JAR" -c "$JAR" "$BASE$1" | sed -n 's/.*name="authenticity_token" value="\([0-9a-f]*\)".*/\1/p' | head -1; }
cookie_value() { awk '$6 == "kilau_session" {print $7}' "$JAR"; }

# Sign up (signs in too): the jar then holds a session cookie for a real user.
T=$(token /signup)
code=$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" -c "$JAR" --data-urlencode "authenticity_token=$T" \
  --data-urlencode "email=$EMAIL" --data-urlencode "password=$PASSWORD" "$BASE/signup")
[ "$code" = 303 ] || { echo "signup answered $code"; exit 1; }
GOOD=$(cookie_value)
# Tamper: flip the last hex digit of the MAC.
last=${GOOD: -1}
if [ "$last" = 0 ]; then flip=1; else flip=0; fi
BAD="${GOOD%?}$flip"
[ "$BAD" != "$GOOD" ] || { echo "tamper failed"; exit 1; }
echo "valid cookie: ${#GOOD} bytes; tampered differs in the last char" >> "$OUT/meta.txt"

# oha_args ROW: sets ARGS for one row (an array, so the header stays one word).
oha_args() {
  case $1 in
    "no cookie")            ARGS=("$BASE/posts") ;;
    "valid session cookie") ARGS=(-H "Cookie: kilau_session=$GOOD" "$BASE/posts") ;;
    "tampered cookie")      ARGS=(-H "Cookie: kilau_session=$BAD" "$BASE/posts") ;;
    "login")                ARGS=(-m POST -T application/x-www-form-urlencoded -H "Cookie: kilau_session=$GOOD" -d "$LOGIN_BODY" "$BASE/login") ;;
  esac
}

# A failed measurement must fail the run, but measure runs inside `{ ... } | tee`,
# a subshell, so a variable would not survive it: the marker is a file.
fail() { echo "MEASUREMENT FAILED: $*" >&2; : > "$WORK/failed"; }

# measure UNIT ROWSPEC...  where ROWSPEC is "row|concurrency". The rows run
# round-robin inside each repetition (row1, row2, ..., row1, row2, ...), so a
# drift in the machine's load hits every row alike instead of the last one.
# Prints one line per row: best of REPS by rate, its p50/p99, all rates, median.
measure() {
  local unit=$1; shift
  local spec row conc rep f n=0
  for spec in "$@"; do   # warm-up, discarded
    row=${spec%|*}; conc=${spec#*|}; oha_args "$row"
    oha --no-tui -z 2s -c "$conc" "${ARGS[@]}" > /dev/null 2>&1 || fail "warm-up oha failed: $unit $row c$conc"
  done
  for rep in $(seq "$REPS"); do
    echo "  rep $rep starts at load $(uptime | sed 's/.*averages: //')" >&2
    n=0
    for spec in "$@"; do
      n=$((n + 1)); row=${spec%|*}; conc=${spec#*|}; oha_args "$row"
      oha --no-tui -z "${DURATION}s" -c "$conc" --output-format json "${ARGS[@]}" > "$RAW/$unit-$n-$rep.json" 2>/dev/null \
        || fail "oha failed: $unit $row c$conc rep $rep"
    done
  done
  printf "%-24s %-4s %9s  %8s  %8s  %8s  %s\n" "row" "conc" "$unit/s" "p50 ms" "p99 ms" "median" "all reps ($unit/s)"
  n=0
  for spec in "$@"; do
    n=$((n + 1)); row=${spec%|*}; conc=${spec#*|}
    ruby -rjson -e '
      js = ARGV[3..-1].map { |f| JSON.parse(File.read(f)) }
      rates = js.map { |j| j["summary"]["requestsPerSec"] }
      b = js[rates.index(rates.max)]; l = b["latencyPercentiles"]
      codes = b["statusCodeDistribution"].map { |k, v| "#{k}:#{v}" }.join(" ")
      printf("%-24s %-4s %9.1f  %8.2f  %8.2f  %8.1f  [%s]  %s\n", ARGV[0], ARGV[1], rates.max, l["p50"] * 1000, l["p99"] * 1000,
             rates.sort[rates.size / 2], rates.map { |x| x.round(1) }.join(" "), codes)' "$row" "c$conc" x "$RAW"/$unit-$n-*.json \
      || fail "result parser failed: $unit $row c$conc"
  done
}

[ -n "${SKIP_GET:-}" ] || {
  echo "== (a) GET /posts (100 posts), best of $REPS x ${DURATION}s, rows interleaved"
  measure req "no cookie|1" "valid session cookie|1" "tampered cookie|1" "no cookie|16" "valid session cookie|16" "tampered cookie|16"
} 2>&1 | tee "$OUT/table-a.txt"

# (b) logins. The CSRF token belongs to the session in GOOD, so the POSTs send it.
TOKEN=$(curl -s -H "Cookie: kilau_session=$GOOD" "$BASE/login" | sed -n 's/.*name="authenticity_token" value="\([0-9a-f]*\)".*/\1/p' | head -1)
LOGIN_BODY="authenticity_token=$TOKEN&email=bench%40example.com&password=$PASSWORD"
{
  echo "== (b) POST /login, valid token and credentials"
  echo "sequential curl, 5 logins (seconds, status):"
  for i in 1 2 3 4 5; do
    curl -s -o /dev/null -w '  %{time_total} s  %{http_code}\n' -H "Cookie: kilau_session=$GOOD" --data "$LOGIN_BODY" "$BASE/login"
  done
  measure login "login|1" "login|8"
} 2>&1 | tee "$OUT/table-b.txt"

# (c) R11: does a login reveal whether the email exists? Round-robin, 7 rounds
# of: unknown email, wrong password, right password (curl time_total, seconds).
{
  echo "== (c) sequential POST /login by kind, 7 rounds, kinds interleaved (seconds)"
  u=""; w=""; r=""
  for i in 1 2 3 4 5 6 7; do
    u="$u $(curl -s -o /dev/null -w '%{time_total}' -H "Cookie: kilau_session=$GOOD" --data "authenticity_token=$TOKEN&email=nobody%40example.com&password=$PASSWORD" "$BASE/login")"
    w="$w $(curl -s -o /dev/null -w '%{time_total}' -H "Cookie: kilau_session=$GOOD" --data "authenticity_token=$TOKEN&email=bench%40example.com&password=not-the-password" "$BASE/login")"
    r="$r $(curl -s -o /dev/null -w '%{time_total}' -H "Cookie: kilau_session=$GOOD" --data "$LOGIN_BODY" "$BASE/login")"
  done
  echo "unknown-email: $u"; echo "wrong-password:$w"; echo "right-password:$r"
} | tee "$OUT/table-c.txt"

{ echo "--- power source and battery state (end)"; pmset -g batt | sed -n '1p;2s/^ -InternalBattery-[0-9]* (id=[0-9]*)//p'; echo "--- load average at end"; uptime | sed 's/.*averages: //'; echo "--- server log lines (not request lines)"; grep -vc '^$' "$LOG"; } >> "$OUT/meta.txt"

[ ! -e "$WORK/failed" ] || { echo "the run is incomplete: a measurement failed (see MEASUREMENT FAILED above)" >&2; exit 1; }
