#!/bin/sh
# Drives a running blog over HTTP. $1: the scratch database path.
set -u
DB="$1"
LOG=/tmp/kilau-e2e-server.log
KILAU_DATABASE_PATH="$DB" KILAU_SERVER_PORT=0 ./build/bin/blog start > "$LOG" 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null' EXIT
i=0
until grep -q "listening on" "$LOG"; do
  i=$((i + 1))
  if [ $i -gt 100 ]; then echo "FAIL: server did not start"; cat "$LOG"; exit 1; fi
  sleep 0.1
done
PORT=$(sed -n 's/.*127\.0\.0\.1:\([0-9]*\).*/\1/p' "$LOG" | head -1)
BASE="http://127.0.0.1:$PORT"
fail=0
expect() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected [$3] got [$2]"; fail=1; fi; }

expect "_ping" "$(curl -s $BASE/_ping)" '{"ok":true}'
expect "root redirects" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' $BASE/)" "303 $BASE/posts"
expect "create post" "$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode 'post[title]=Halo <e2e>' --data-urlencode 'post[content]=Isi' $BASE/posts)" "303"
expect "list shows it escaped" "$(curl -s $BASE/posts | grep -c 'Halo &lt;e2e&gt;')" "1"
expect "invalid post is 422" "$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode 'post[title]=a' --data-urlencode 'post[content]=' $BASE/posts)" "422"
expect "update via _method" "$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode '_method=patch' --data-urlencode 'post[title]=Halo lagi' --data-urlencode 'post[content]=Baru' $BASE/posts/1)" "303"
expect "missing post is 404" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/999)" "404"
expect "bad id is 400" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/abc)" "400"
codes=$(seq 200 | xargs -P 32 -I{} curl -s -o /dev/null -w '%{http_code}\n' $BASE/posts | sort | uniq -c | awk '{print $2 ":" $1}' | tr '\n' ' ')
expect "200 requests at 32 concurrent all 200" "$codes" "200:200 "
expect "delete via _method" "$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode '_method=delete' $BASE/posts/1)" "303"
expect "requests were logged" "$(grep -c '^GET /posts 200 ' "$LOG" | awk '{print ($1 >= 200) ? "yes" : "no"}')" "yes"
exit $fail
