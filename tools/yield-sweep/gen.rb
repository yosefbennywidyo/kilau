# K-030 sweep generator (kilau). Usage: ruby gen.rb <outdir>
# Writes one probe per (builtin name, args) over yield-receiver kinds, plus index.txt.
# Generates one probe program per (method, args) over the yield-receiver
# kinds CRuby accepts, and writes the candidate list.
SAMPLES = {
  "7" => "Integer", "2.5" => "Float", '"abc"' => "String", ":ab" => "Symbol",
  "[3, 1, 2]" => "Array", '["b", "a"]' => "StrArray", "{a: 1}" => "Hash"
}
DENY = %i[exit exit! abort sleep fork exec system spawn gets print puts p pp putc printf display
  syscall trap warn raise fail throw catch loop require load open binding srand rand
  shuffle shuffle! sample instance_eval instance_exec method methods public_method singleton_method
  send __send__ public_send define_singleton_method extend freeze hash object_id __id__ to_enum enum_for
  each each_with_index each_index each_char each_byte each_line each_pair each_key each_value
  times upto downto step tap then yield_self itself_ instance_variable_set taint untaint
  method_missing respond_to_missing? initialize clone dup]
names = SAMPLES.keys.flat_map { |src|
  v = eval(src)
  v.public_methods.map(&:to_sym)
}.tally.select { |_, c| c >= 2 }.keys
names = names.reject { |n| DENY.include?(n) || n.to_s.end_with?("=") || n.to_s =~ /\A(?:__|is_|instance_|define_|remove_|set_)/ }
ARGVARS = ["", "2", "1, 2"]
out = []
names.sort.each do |n|
  ARGVARS.each do |a|
    sites = SAMPLES.select do |src, _|
      begin
        v = eval(src)
        v.public_send(n, *(a.empty? ? [] : eval("[#{a}]")))
        true
      rescue Exception
        false
      end
    end
    next if sites.size < 2
    body = sites.keys.map { |src| "w { #{src} }" }.join("\n")
    prog = <<~RB
      def w
        v = yield.#{n}#{a.empty? ? "" : "(#{a})"}
        p v
      end
      #{body}
    RB
    out << [n, a, sites.keys, prog]
  end
end
dir = ARGV[0]
out.each_with_index do |(n, a, srcs, prog), i|
  File.write(File.join(dir, format("p%04d_%s.rb", i, n.to_s.gsub(/[^A-Za-z0-9]/) { |c| "_#{c.ord}" })), prog)
end
File.write(File.join(dir, "index.txt"), out.each_with_index.map { |(n, a, srcs, _), i| format("p%04d\t%s\t%s", i, n, a) }.join("\n") + "\n")
puts "candidates: #{names.size} names, probes: #{out.size}"
