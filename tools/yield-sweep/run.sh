#!/bin/bash
# K-030 sweep runner. Usage: run.sh <probe.rb>; prints "<probe> RUBY_ERR|CC_FAIL|MISMATCH|OK".
# SPINEL overrides the compiler path (default: spinel on PATH).
SPINEL="${SPINEL:-spinel}"
f="$1"; b="${f%.rb}"
ruby "$f" > "$b.ruby.out" 2>&1 || { echo "$f RUBY_ERR"; exit 0; }
if ! "$SPINEL" "$f" -o "$b.bin" > "$b.cc.log" 2>&1; then echo "$f CC_FAIL"; exit 0; fi
timeout 10 "./$b.bin" > "$b.spn.out" 2>&1
if diff -q "$b.ruby.out" "$b.spn.out" >/dev/null; then echo "$f OK"; else echo "$f MISMATCH"; fi
