# One request per process, workers = cores. Reforking is left off: it is
# Linux-only, and this benchmark runs on macOS.
worker_processes Integer(ENV.fetch("WEB_CONCURRENCY", 8))
listen "127.0.0.1:#{ENV.fetch("PORT", 3000)}"
