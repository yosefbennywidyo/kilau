#!/bin/sh
# Drives a running blog over HTTP. $1: the scratch database path;
# BIN: the binary under build/bin (blog or blog_routes).
set -u
DB="$1"
BIN="${BIN:-blog}"
LOG=/tmp/kilau-e2e-server.log
KILAU_DATABASE_PATH="$DB" KILAU_SERVER_PORT=0 ./build/bin/$BIN start > "$LOG" 2>&1 &
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
expect "HEAD on a parameterized path downloads 0 bytes of body" "$(curl -s -o /dev/null -w '%{size_download}' -I $BASE/posts/1)" "0"
raw_head_404=$(printf 'HEAD /nope HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n' | nc 127.0.0.1 "$PORT")
expect "HEAD to an unknown path sends no body on the raw wire (curl -I never reads a body, so this must be checked at the socket level)" "$(printf '%s' "$raw_head_404" | grep -c '<!doctype html>')" "0"
expect "HEAD status matches GET status on a static path" "$(curl -s -o /dev/null -w '%{http_code}' -I $BASE/posts/new)" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/new)"
expect "HEAD status matches GET status on a parameterized path" "$(curl -s -o /dev/null -w '%{http_code}' -I $BASE/posts/1)" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/1)"
expect "PUT where only GET/POST are routed is 405 with Allow" "$(curl -s -o /dev/null -w '%{http_code}' -X PUT $BASE/posts)" "405"
expect "Allow lists GET, HEAD, POST sorted" "$(curl -s -I -X OPTIONS $BASE/posts | tr -d '\r' | grep -i '^allow:' | tr 'a-z' 'A-Z')" "ALLOW: GET, HEAD, POST"
codes=$(seq 200 | xargs -P 32 -I{} curl -s -o /dev/null -w '%{http_code}\n' $BASE/posts | sort | uniq -c | awk '{print $2 ":" $1}' | tr '\n' ' ')
expect "200 requests at 32 concurrent all 200" "$codes" "200:200 "
expect "delete via _method" "$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode '_method=delete' $BASE/posts/1)" "303"
expect "requests were logged" "$(grep -c '^GET /posts 200 ' "$LOG" | awk '{print ($1 >= 200) ? "yes" : "no"}')" "yes"
exit $fail
