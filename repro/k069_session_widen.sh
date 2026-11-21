#!/bin/bash
# K-069: counts the --warn-widen warnings that name framework/kilau/session/session.rb when
# framework/test/session_test.rb is compiled, then again on a scratch copy where Session's
# [] and []= are renamed get and set (and the test's callers with them). Not minimal (the whole
# framework is analyzed); a shell script so the repro/*.rb comparison does not pick it up.
# Needs spinel, spin and ruby on PATH. Never modifies the repo; the scratch copy is removed.
set -u
REPO=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d /tmp/k069.XXXXXX)
trap 'rm -rf "${TMP:?}"' EXIT

count() {  # count DIR LABEL: warnings naming session/session.rb in DIR/test/session_test.rb
  local dir=$1 label=$2
  (cd "$dir" && spinel --warn-widen $(spin flags) test/session_test.rb -o "$TMP/bin-$label") > "$TMP/$label.log" 2>&1
  echo "$label: compile exit $?, warnings naming session.rb: $(grep -c 'session/session.rb:[0-9]*:[0-9]*: warning' "$TMP/$label.log")"
  grep 'session/session.rb:[0-9]*:[0-9]*: warning' "$TMP/$label.log" | sed 's/.*session\/session.rb:\([0-9]*\):[0-9]*: warning: /  line \1: /' | cut -c1-90
}

count "$REPO/framework" original

cp -R "$REPO/framework" "$TMP/fw"
ruby -e '
  f = "#{ARGV[0]}/kilau/session/session.rb"
  File.write(f, File.read(f).sub("def [](key)", "def get(key)").sub("def []=(key, value)", "def set(key, value)"))
  t = "#{ARGV[0]}/test/session_test.rb"
  src = File.read(t)
  src = src.gsub(/^(\s*)(s|vs|ks|forged)\["([^"]*)"\] = (.+)$/) { "#{$1}#{$2}.set(\"#{$3}\", #{$4})" }
  src = src.gsub(/\b(s|back|fresh)\["([^"]*)"\]/) { "#{$1}.get(\"#{$2}\")" }
  src = src.gsub(/(Kilau::Session\.load\(ks\.to_cookie_value, SECRET\))\["([^"]*)"\]/) { "#{$1}.get(\"#{$2}\")" }
  File.write(t, src)
' "$TMP/fw"
count "$TMP/fw" renamed
