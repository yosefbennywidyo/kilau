# One request per process, workers = cores. Reforking is left off: it is
# Linux-only, and this benchmark runs on macOS.
worker_processes Integer(ENV.fetch("WEB_CONCURRENCY", 8))
# Behind nginx it listens on a Unix socket (LISTEN): Pitchfork closes every
# connection, and a new TCP connection per request runs the machine out of
# local ports within seconds.
listen ENV.fetch("LISTEN") { "127.0.0.1:#{ENV.fetch("PORT", 3000)}" }
