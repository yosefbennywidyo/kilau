# Standalone: times one Kilau::Password.digest at three iteration counts,
# best of three, in milliseconds. Not a test, not in the make targets.
#   CRuby:  ruby $(spin flags includes) bench/password_cost.rb
#   Spinel: (cd framework && spinel $(spin flags) ../bench/password_cost.rb -o /tmp/password_cost) && /tmp/password_cost
#           (spinel's default optimization level, -O2)
require "kilau"

def now_ms
  Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000.0
end

[100_000, 300_000, 600_000].each do |iterations|
  best = nil
  3.times do
    t0 = now_ms
    Kilau::Password.digest("benchmark password", iterations)
    elapsed = now_ms - t0
    best = elapsed if best.nil? || elapsed < best
  end
  puts "#{iterations} iterations: best of 3 = #{best.round(1)} ms"
end
