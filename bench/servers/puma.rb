# The same shape as bench/rails_blog/config/puma.rb: workers = cores, 5 threads.
workers Integer(ENV.fetch("WEB_CONCURRENCY", 8))
threads 5, 5
# LISTEN (a Unix socket path) replaces the TCP port: kilau-puma-unix in
# run.sh, to compare with Pitchfork on equal terms behind nginx.
bind ENV.key?("LISTEN") ? "unix://#{ENV["LISTEN"]}" : "tcp://127.0.0.1:#{ENV.fetch("PORT", 3000)}"
environment "production"
preload_app!
