# Shared by bench/check_bodies.sh and bench/run.sh (bash). Starts and
# stops the three apps the benchmark compares (spec §6.1):
#   kilau        examples/blog/build/bin/blog         (route table, procs)
#   kilau-routes examples/blog/build/bin/blog_routes  (kilau gen routes)
#   rails        bench/rails_blog under Puma
BENCH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BLOG=$(cd "$BENCH/../examples/blog" && pwd)
CORES=${CORES:-$(sysctl -n hw.ncpu)}
POOL=${POOL:-5}
SEED_DB=${SEED_DB:-/tmp/kilau-bench-seed.sqlite3}
APP_PID=""

# A migrated database with the 100 posts of bench/seed.sql.
make_seed_db() {
  rm -f "$SEED_DB" "$SEED_DB-wal" "$SEED_DB-shm"
  (cd "$BLOG" && KILAU_ENV=production KILAU_DATABASE_PATH="$SEED_DB" ./build/bin/blog db migrate) > /dev/null || return 1
  sqlite3 "$SEED_DB" < "$BENCH/seed.sql"
}

# fresh_db PATH: a copy of the seed, so no cell sees another's inserts.
fresh_db() {
  rm -f "$1" "$1-wal" "$1-shm"
  cp "$SEED_DB" "$1"
}

# start_app APP PORT DB LOG: starts it in the background, sets APP_PID.
start_app() {
  local app=$1 port=$2 db=$3 log=$4
  case $app in
    kilau|kilau-routes)
      local bin=blog
      [ "$app" = kilau-routes ] && bin=blog_routes
      # The binary reads config/<KILAU_ENV>.yaml from the app directory.
      (cd "$BLOG" && exec env KILAU_ENV=production KILAU_DATABASE_PATH="$db" KILAU_SERVER_PORT="$port" \
        KILAU_DATABASE_POOL="$POOL" KILAU_LOGGER_REQUESTS=false SPINEL_WORKERS="$CORES" \
        "./build/bin/$bin" start) > "$log" 2>&1 &
      APP_PID=$!
      ;;
    rails)
      mkdir -p "$BENCH/rails_blog/log" "$BENCH/rails_blog/tmp"
      (cd "$BENCH/rails_blog" && exec env RAILS_ENV=production DATABASE_PATH="$db" PORT="$port" \
        WEB_CONCURRENCY="$CORES" RAILS_MAX_THREADS="$POOL" RAILS_LOG="$log.rails" \
        bundle exec puma -C config/puma.rb) > "$log" 2>&1 &
      APP_PID=$!
      ;;
    *) echo "unknown app $app" >&2; return 1 ;;
  esac
}

# wait_ready PORT: polls /_ping every 10 ms; prints the milliseconds it
# took, or fails after 60 s.
wait_ready() {
  local start now
  start=$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')
  for _ in $(seq 6000); do
    if [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$1/_ping")" = 200 ]; then
      now=$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')
      echo $((now - start))
      return 0
    fi
    sleep 0.01
  done
  return 1
}

# The RSS in KB of APP_PID and its children (Puma's workers).
tree_rss() {
  local pids total=0 rss
  pids="$APP_PID $(pgrep -P "$APP_PID" | tr '\n' ' ')"
  for p in $pids; do
    rss=$(ps -o rss= -p "$p" 2>/dev/null | tr -d ' ')
    [ -n "$rss" ] && total=$((total + rss))
  done
  echo $total
}

# Stops APP_PID and its children: Puma forwards TERM to its workers, but
# a KILL of the master alone would orphan them on the port.
stop_app() {
  [ -z "$APP_PID" ] && return 0
  local children
  children=$(pgrep -P "$APP_PID" | tr '\n' ' ')
  kill "$APP_PID" 2>/dev/null
  for _ in $(seq 100); do kill -0 "$APP_PID" 2>/dev/null || break; sleep 0.1; done
  kill -9 "$APP_PID" $children 2>/dev/null
  wait "$APP_PID" 2>/dev/null
  APP_PID=""
}
