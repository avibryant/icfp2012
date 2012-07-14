command = ARGV.shift
dir = ARGV.shift
iterations = ARGV.size > 0 ? ARGV.shift.to_f : 1

d = Dir.new(dir)
d.select {|f| f[0 .. 0] != "."}.each do |filename|
  filenameMetaData = filename.split("-")
  m = filenameMetaData.length > 1 ? filenameMetaData[0].to_i : 1
  (iterations*m).to_i.times do
    started = Time.now
    output = `#{command} < #{dir}#{filename}`
    finished = Time.now
    lastline = output.split("\n")[-1]
    puts "#{filename}\t#{finished - started}\t#{started.strftime("%Y-%m-%d %H:%M:%S")}\t#{lastline}"
  end
end
