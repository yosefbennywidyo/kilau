# The same shape as bench/rails_blog/config/puma.rb: workers = cores, 5 threads.
workers Integer(ENV.fetch("WEB_CONCURRENCY", 8))
threads 5, 5
bind "tcp://127.0.0.1:#{ENV.fetch("PORT", 3000)}"
environment "production"
preload_app!
