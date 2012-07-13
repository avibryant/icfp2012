require 'map'

map = Map.parse(STDIN.read)
puts map.move_rocks.to_s
