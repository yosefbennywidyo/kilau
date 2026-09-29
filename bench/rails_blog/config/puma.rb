# spec §6.1: workers = cores, 5 threads each.
workers Integer(ENV.fetch("WEB_CONCURRENCY", 8))
threads 5, 5
port Integer(ENV.fetch("PORT", 3000))
bind "tcp://127.0.0.1:#{ENV.fetch("PORT", 3000)}"
environment "production"
preload_app!
