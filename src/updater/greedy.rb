require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

map = Map.parse(STDIN.read)

commands = []
position = nil

while !(map.is_done? || position == map.metadata["RobotPosition"])
  map.score_cells!
  puts "Move ##{commands.size}"
  puts map
  puts commands.join
  position = map.metadata["RobotPosition"]
  robot = map[*position]
  move_values = DIRECTIONS.zip(DIRECTIONS.map {|d| robot.cell_at(d).value })
  best_move = move_values.sort_by {|p| p[1] }.last[0]
  command = DIRECTION_COMMANDS[best_move]
  map = map.command_robot(command).move_rocks
  commands << command
  puts "---"
end

puts "!!!"
puts map
puts commands.join

