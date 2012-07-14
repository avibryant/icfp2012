require 'map'

map = Map.parse(STDIN.read)
move = ARGV[0]
puts map.command_robot(move).move_rocks.to_s