#!/bin/bash
# The gate before a benchmark session (spec §6.1): every app answers S1-S3
# with the same bytes and S4 with 303 to the same place. Exit 1 if not.
set -u
source "$(dirname "$0")/lib.sh"
# An interrupted or failing run must not leave an app on the port.
trap stop_app EXIT
trap 'exit 130' INT TERM
make_seed_db || { echo "FAIL: cannot build the seed database"; exit 1; }
DIR=/tmp/kilau-bench-bodies
rm -rf "$DIR"; mkdir -p "$DIR"
fail=0
for app in kilau kilau-routes rails; do
  fresh_db "$DIR/$app.sqlite3"
  start_app "$app" 5199 "$DIR/$app.sqlite3" "$DIR/$app.log"
  if ! wait_ready 5199 > /dev/null; then echo "FAIL: $app did not start"; cat "$DIR/$app.log"; stop_app; exit 1; fi
  curl -s http://127.0.0.1:5199/_ping > "$DIR/$app.s1"
  curl -s http://127.0.0.1:5199/posts/7 > "$DIR/$app.s2"
  curl -s http://127.0.0.1:5199/posts > "$DIR/$app.s3"
  curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --data-urlencode 'post[title]=Bench post' \
    --data-urlencode 'post[content]=Isi' http://127.0.0.1:5199/posts | sed 's|http://127.0.0.1:5199||' > "$DIR/$app.s4"
  stop_app
done
for s in s1 s2 s3 s4; do
  for app in kilau-routes rails; do
    if cmp -s "$DIR/kilau.$s" "$DIR/$app.$s"; then
      echo "ok   $s kilau == $app ($(wc -c < "$DIR/kilau.$s" | tr -d ' ') bytes)"
    else
      echo "FAIL $s kilau != $app"; diff "$DIR/kilau.$s" "$DIR/$app.$s" | head -20; fail=1
    fi
  done
done
exit $fail
