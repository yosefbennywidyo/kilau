# Turns one bench/servers/run.sh results directory into a Markdown table:
# the median of the measured runs per cell. CRuby only.
#
#   ruby bench/servers/summarize.rb bench/results/<stamp>-servers
require "json"

dir = ARGV.fetch(0)
APPS = %w[kilau-spinel kilau-spinel-direct kilau-cruby kilau-puma kilau-puma-direct kilau-pitchfork kilau-falcon rails-puma].freeze
NAMES = { "s1" => "S1 `GET /_ping`", "s2" => "S2 `GET /posts/:id`", "s3" => "S3 `GET /posts` (100 rows)", "s4" => "S4 `POST /posts`" }.freeze

def median(values)
  sorted = values.sort
  sorted.empty? ? nil : sorted[sorted.size / 2]
end

cells = {}
Dir[File.join(dir, "*.r*.json")].sort.each do |path|
  next unless File.basename(path) =~ /\A(.+)-(s\d)-c(\d+)\.r\d+\.json\z/
  key = [$1, $2, $3.to_i]
  data = JSON.parse(File.read(path))
  codes = data["statusCodeDistribution"].to_h
  expected = key[1] == "s4" ? "303" : "200"
  cell = (cells[key] ||= { rps: [], p50: [], p99: [], bad: 0, errors: 0 })
  cell[:rps] << data["summary"]["requestsPerSec"]
  cell[:p50] << data["latencyPercentiles"]["p50"] * 1000
  cell[:p99] << data["latencyPercentiles"]["p99"] * 1000
  cell[:bad] += codes.reject { |code, _| code == expected }.values.sum
  # oha counts the requests cut by -z as errors; only other errors matter.
  cell[:errors] += data["errorDistribution"].to_h.reject { |e, _| e.include?("aborted due to deadline") }.values.sum
end

puts File.read(File.join(dir, "meta.txt")).lines.map { |line| "- #{line}" }.join
cells.keys.map { |_, s, c| [s, c] }.uniq.sort.each do |s, c|
  puts "", "## #{NAMES.fetch(s)}, #{c} connection#{"s" if c > 1}", ""
  puts "| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |"
  puts "|---|---|---|---|---|---|---|---|---|"
  md5s = APPS.map { |app| f = File.join(dir, "#{app}-#{s}-c#{c}.md5"); File.exist?(f) ? File.read(f).strip : nil }.compact.uniq
  APPS.each do |app|
    cell = cells[[app, s, c]] or next
    base = File.join(dir, "#{app}-#{s}-c#{c}")
    rss = File.readlines("#{base}.rss").map(&:to_i).max.to_f / 1024
    body = File.exist?("#{base}.md5") ? (md5s.size == 1 ? "same" : File.read("#{base}.md5")[0, 8]) : "—"
    puts format("| %s | %d | %.2f | %.2f | %d | %d | %s | %.0f | %s |", app, median(cell[:rps]), median(cell[:p50]), median(cell[:p99]),
                cell[:bad], cell[:errors], File.read("#{base}.startup_ms").strip, rss, body)
  end
end
