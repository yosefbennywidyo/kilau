# The blog's own config.ru, run from the blog directory so its config/ and
# assets resolve; KILAU_SQLITE_LIB is the sqlite package's directory.
BLOG = File.expand_path("../../examples/blog", __dir__)
$LOAD_PATH.unshift(File.expand_path("../../framework", __dir__))
$LOAD_PATH.unshift(ENV.fetch("KILAU_SQLITE_LIB"))
Dir.chdir(BLOG)
instance_eval(File.read(File.join(BLOG, "config.ru")), File.join(BLOG, "config.ru"))
