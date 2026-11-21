#!/bin/sh
# Drives a running blog over HTTP. $1: the scratch database path;
# BIN: the binary under build/bin (blog or blog_routes).
set -u
DB="$1"
BIN="${BIN:-blog}"
LOG=/tmp/kilau-e2e-server.log
JAR=/tmp/kilau-e2e-jar.$$
JAR0=/tmp/kilau-e2e-jar0.$$
KILAU_DATABASE_PATH="$DB" KILAU_SERVER_PORT=0 ./build/bin/$BIN start > "$LOG" 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null; rm -f $JAR $JAR0' EXIT
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

# The authenticity token an HTML form at $1 carries, read with the cookie jar $2.
token() { curl -s -b "$2" -c "$2" "$BASE$1" | sed -n 's/.*name="authenticity_token" value="\([0-9a-f]*\)".*/\1/p' | head -1; }
# Status of a form POST: code JAR path field...
post_code() { jar=$1; path=$2; shift 2; curl -s -o /dev/null -w '%{http_code}' -b "$jar" -c "$jar" "$@" "$BASE$path"; }

expect "_ping" "$(curl -s $BASE/_ping)" '{"ok":true}'
expect "root redirects" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' $BASE/)" "303 $BASE/posts"
expect "new post form without a login redirects to /login" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -b $JAR0 -c $JAR0 $BASE/posts/new)" "303 $BASE/login"
T=$(token /signup $JAR)
expect "signup form carries a 64-hex token" "$(printf '%s' "$T" | grep -c '^[0-9a-f]\{64\}$')" "1"
expect "signup without a token is 403" "$(post_code $JAR0 /signup --data-urlencode 'email=x@example.com' --data-urlencode 'password=longenough1')" "403"
expect "signup with a bad email is 422" "$(post_code $JAR /signup --data-urlencode "authenticity_token=$T" --data-urlencode 'email=nope' --data-urlencode 'password=longenough1')" "422"
expect "signup signs in (303 to /posts)" "$(post_code $JAR /signup --data-urlencode "authenticity_token=$T" --data-urlencode 'email=e2e@example.com' --data-urlencode 'password=longenough1')" "303"
expect "a second signup with the same email is 422" "$(post_code $JAR0 /signup --data-urlencode "authenticity_token=$(token /signup $JAR0)" --data-urlencode 'email=e2e@example.com' --data-urlencode 'password=longenough1')" "422"
expect "the session cookie is HttpOnly" "$(grep -c '^#HttpOnly_.*kilau_session' $JAR)" "1"
T=$(token /posts/new $JAR)
expect "new post form with a login is 200" "$(curl -s -o /dev/null -w '%{http_code}' -b $JAR -c $JAR $BASE/posts/new)" "200"
expect "create post" "$(post_code $JAR /posts --data-urlencode "authenticity_token=$T" --data-urlencode 'post[title]=Halo <e2e>' --data-urlencode 'post[content]=Isi')" "303"
expect "create post without a token is 403" "$(post_code $JAR /posts --data-urlencode 'post[title]=Tanpa token' --data-urlencode 'post[content]=Isi')" "403"
expect "create post with a wrong token is 403" "$(post_code $JAR /posts --data-urlencode "authenticity_token=$(printf '%064d' 0)" --data-urlencode 'post[title]=Salah token' --data-urlencode 'post[content]=Isi')" "403"
expect "list shows it escaped" "$(curl -s $BASE/posts | grep -c 'Halo &lt;e2e&gt;')" "1"
expect "invalid post is 422" "$(post_code $JAR /posts --data-urlencode "authenticity_token=$T" --data-urlencode 'post[title]=a' --data-urlencode 'post[content]=')" "422"
expect "update via _method" "$(post_code $JAR /posts/1 --data-urlencode "authenticity_token=$T" --data-urlencode '_method=patch' --data-urlencode 'post[title]=Halo lagi' --data-urlencode 'post[content]=Baru')" "303"
expect "missing post is 404" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/999)" "404"
expect "bad id is 400" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/abc)" "400"
expect "HEAD on a parameterized path downloads 0 bytes of body" "$(curl -s -o /dev/null -w '%{size_download}' -I $BASE/posts/1)" "0"
raw_head_404=$(printf 'HEAD /nope HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n' | nc 127.0.0.1 "$PORT")
expect "HEAD to an unknown path sends no body on the raw wire (curl -I never reads a body, so this must be checked at the socket level)" "$(printf '%s' "$raw_head_404" | grep -c '<!doctype html>')" "0"
expect "HEAD status matches GET status on a static path" "$(curl -s -o /dev/null -w '%{http_code}' -I $BASE/posts/new)" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/new)"
expect "HEAD status matches GET status on a parameterized path" "$(curl -s -o /dev/null -w '%{http_code}' -I $BASE/posts/1)" "$(curl -s -o /dev/null -w '%{http_code}' $BASE/posts/1)"
expect "PUT without a token is 403 (the CSRF check runs before routing)" "$(curl -s -o /dev/null -w '%{http_code}' -X PUT $BASE/posts)" "403"
expect "PUT where only GET/POST are routed is 405 with Allow" "$(post_code $JAR /posts -X PUT --data-urlencode "authenticity_token=$T")" "405"
expect "Allow lists GET, HEAD, POST sorted" "$(curl -s -I -X OPTIONS $BASE/posts | tr -d '\r' | grep -i '^allow:' | tr 'a-z' 'A-Z')" "ALLOW: GET, HEAD, POST"
codes=$(seq 200 | xargs -P 32 -I{} curl -s -o /dev/null -w '%{http_code}\n' $BASE/posts | sort | uniq -c | awk '{print $2 ":" $1}' | tr '\n' ' ')
expect "200 requests at 32 concurrent all 200" "$codes" "200:200 "
expect "delete without a token is 403" "$(post_code $JAR /posts/1 --data-urlencode '_method=delete')" "403"
expect "delete via _method" "$(post_code $JAR /posts/1 --data-urlencode "authenticity_token=$T" --data-urlencode '_method=delete')" "303"
expect "signing out redirects" "$(post_code $JAR /logout --data-urlencode "authenticity_token=$T")" "303"
expect "create after signing out redirects to /login" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -b $JAR -c $JAR --data-urlencode "authenticity_token=$(token /login $JAR)" --data-urlencode 'post[title]=Tamu' --data-urlencode 'post[content]=x' $BASE/posts)" "303 $BASE/login"
TL=$(token /login $JAR)
expect "sign in with a wrong password is 422" "$(post_code $JAR /login --data-urlencode "authenticity_token=$TL" --data-urlencode 'email=e2e@example.com' --data-urlencode 'password=wrongwrong')" "422"
expect "sign in with the right password is 303" "$(post_code $JAR /login --data-urlencode "authenticity_token=$TL" --data-urlencode 'email=e2e@example.com' --data-urlencode 'password=longenough1')" "303"
expect "signed in again, the new post form is 200" "$(curl -s -o /dev/null -w '%{http_code}' -b $JAR -c $JAR $BASE/posts/new)" "200"
warnings=$(grep -c 'built-in development key' "$LOG")
if [ -n "${KILAU_SESSION_SECRET:-}" ]; then
  expect "no development-key warning when KILAU_SESSION_SECRET is set" "$warnings" "0"
else
  expect "one development-key warning on stderr" "$warnings" "1"
fi
expect "requests were logged" "$(grep -c '^GET /posts 200 ' "$LOG" | awk '{print ($1 >= 200) ? "yes" : "no"}')" "yes"
exit $fail
