#!/usr/bin/env ruby

USAGE = "#{File.basename(__FILE__)} <basename> <maxcount>"
BASE_URL = "http://www-fp.cs.st-andrews.ac.uk/~icfppc/maps/%s.map"

basename = ARGV.shift

if basename.nil? || basename =~ /help/i
  STDERR.puts(USAGE)
  exit(1)
end

maxcount = (ARGV.shift || 1).to_i

(0...maxcount).each do |i|
  mapname = "#{basename}#{i+1}"
  url = BASE_URL % mapname
  cmd = "mkdir -p #{mapname} && cd #{mapname} && curl -o base #{url} && cd .."
  puts cmd
  puts `#{cmd}`
end
