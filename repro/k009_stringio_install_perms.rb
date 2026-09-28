# K-009: StringIO fails to link because its package objects were installed
# root-only (0640) under /usr/local/lib/spinel/packages/stringio/.
# Run: spinel --require-gate repro/k009_stringio_install_perms.rb -o /tmp/k009
require "stringio"
io = StringIO.new("a\nb\n")
puts io.gets
