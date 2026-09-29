# Turns one bench/run.sh results directory into bench/RESULTS.md (spec
# §6.2): the median of the measured runs per cell, with the session's
# machine, versions and commit. CRuby only; it reads what oha wrote.
#
#   ruby bench/summarize.rb bench/results/<stamp> > bench/RESULTS.md
require "json"

dir = ARGV.fetch(0)
meta = File.readlines(File.join(dir, "meta.txt"), chomp: true).to_h { |line| line.split("=", 2) }
APPS = %w[kilau kilau-routes rails].freeze
SCENARIOS = { "s1" => "S1 `GET /_ping`", "s2" => "S2 `GET /posts/:id`", "s3" => "S3 `GET /posts` (100 baris)", "s4" => "S4 `POST /posts`" }.freeze

def median(values)
  sorted = values.compact.sort
  return nil if sorted.empty?
  mid = sorted.size / 2
  sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
end

def fmt(value, digits = 0) = value.nil? ? "—" : format("%.#{digits}f", value)

cells = {}
Dir[File.join(dir, "*.r*.json")].sort.each do |path|
  name = File.basename(path)
  next unless name =~ /\A(.+)-(s\d)-c(\d+)\.r\d+\.json\z/
  key = [$1, $2, $3.to_i]
  data = JSON.parse(File.read(path))
  codes = data["statusCodeDistribution"].to_h
  expected = key[1] == "s4" ? "303" : "200"
  cell = (cells[key] ||= { rps: [], p50: [], p99: [], bad: 0, errors: 0 })
  cell[:rps] << data.dig("summary", "requestsPerSec")
  cell[:p50] << data.dig("latencyPercentiles", "p50")
  cell[:p99] << data.dig("latencyPercentiles", "p99")
  cell[:bad] += codes.reject { |code, _| code == expected }.values.sum
  # oha counts the requests cut by -z as errors; only other errors matter.
  cell[:errors] += data["errorDistribution"].to_h.reject { |e, _| e.include?("aborted due to deadline") }.values.sum
end

def cell_file(dir, app, s, c, ext) = File.join(dir, "#{app}-#{s}-c#{c}.#{ext}")

puts "# Hasil benchmark Kilau vs Rails"
puts
puts "- Sesi: #{meta["date"]}, commit Kilau `#{meta["kilau_sha"]}`"
puts "- Mesin: #{meta["machine"]}, #{meta["os"]}"
puts "- Versi: #{meta["spinel"]}; #{meta["ruby"]}; Rails #{meta["rails"]}; #{meta["puma"]}; #{meta["oha"]}"
puts "- Prosedur: pemanasan #{meta["warmup"]} dtk, lalu #{meta["reps"]} × #{meta["duration"]} dtk per sel; angka = median. Pool DB #{meta["pool"]}. Setiap sel memakai salinan baru DB seed (100 post) dan proses app baru."
puts "- `kilau` = route table dengan proc (Rencana 2); `kilau-routes` = `kilau gen routes`; `rails` = Rails + Puma (workers = core, 5 thread), YJIT."
puts "- Data mentah: `#{dir}`"
puts
SCENARIOS.each do |s, title|
  puts "## #{title}"
  puts
  if cells.keys.none? { |_, sc, _| sc == s }
    puts "(tidak diukur di sesi ini)"
    puts
    next
  end
  puts "| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |"
  puts "|---|---|---|---|---|---|---|"
  APPS.each do |app|
    cells.keys.select { |a, sc, _| a == app && sc == s }.map(&:last).sort.each do |c|
      cell = cells[[app, s, c]]
      p50 = median(cell[:p50])
      p99 = median(cell[:p99])
      puts "| #{app} | #{c} | #{fmt(median(cell[:rps]))} | #{fmt(p50 && p50 * 1000, 2)} | #{fmt(p99 && p99 * 1000, 2)} | #{cell[:bad]} | #{cell[:errors]} |"
    end
  end
  puts
end

puts "## Start, memori, artefak"
puts
puts "| App | Start → 200 pertama, median (ms) | RSS puncak, maks semua sel (MB) | Artefak deploy | Waktu build (dtk) |"
puts "|---|---|---|---|---|"
APPS.each do |app|
  starts = Dir[File.join(dir, "#{app}-s*-c*.startup_ms")].map { |f| File.read(f).to_i }
  next if starts.empty?
  rss = Dir[File.join(dir, "#{app}-s*-c*.rss")].flat_map { |f| File.readlines(f).map(&:to_i) }.max.to_i
  artifact = case app
             when "kilau" then "#{fmt(meta["artifact_kilau_bytes"].to_i / 1048576.0, 1)} MB (satu binary)"
             when "kilau-routes" then "#{fmt(meta["artifact_kilau_routes_bytes"].to_i / 1048576.0, 1)} MB (satu binary)"
             else "#{fmt(meta["artifact_rails_kb"].to_i / 1024.0, 1)} MB app + vendor/bundle (+ CRuby)"
             end
  build = meta.fetch("build_#{app.tr("-", "_")}_s", "—")
  puts "| #{app} | #{median(starts)} | #{fmt(rss / 1024.0, 1)} | #{artifact} | #{build} |"
end
