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
  # Every Session call site: a local that holds a Session, or a Kilau::Session.load(...) result
  # (one level of nested parentheses in its arguments). Unrelated String/Hash indexing, which
  # never has a string-literal key on these receivers, is left alone.
  recv = /(?:\b(?:s|vs|ks|forged|back|fresh|rs|other)\b|Kilau::Session\.load\((?:[^()]|\([^()]*\))*\))/
  val  = /"(?:[^"\\]|\\.)*"|[\w.]+/
  src = src.gsub(/(#{recv})\["((?:[^"\\]|\\.)*)"\] = (#{val})/) { "#{$1}.set(\"#{$2}\", #{$3})" }
  src = src.gsub(/(#{recv})\["((?:[^"\\]|\\.)*)"\]/) { "#{$1}.get(\"#{$2}\")" }
  File.write(t, src)
  # The comparison is only valid if no call site was missed: report any string-literal index
  # that is still on a Session receiver, and stop (exit 3) when there is one.
  left = src.lines.each_with_index.select { |l, _| l =~ /(#{recv})\["/ }
  unless left.empty?
    left.each { |l, i| warn "missed call site, line #{i + 1}: #{l.strip}" }
    exit 3
  end
' "$TMP/fw" || { echo "rewrite incomplete: the comparison would not be valid" >&2; exit 1; }
count "$TMP/fw" renamed
