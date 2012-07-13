require 'map'

map = Map.parse(STDIN.read)
move = ARGV[0]
puts map.move_robot(move).move_rocks.to_s
