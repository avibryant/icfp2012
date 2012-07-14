require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

map = Map.parse(STDIN.read)

commands = []
last_position = nil

while !map.is_done?
  puts "---"
  map.score_cells!
  puts map
  puts commands.join
  position = map.metadata["RobotPosition"]
  robot = map[*position]
  avail_moves = DIRECTIONS.dup
  # one special rule: don't move down with a rock overhead
  p [robot.above.class, robot.right.class, robot.below.class, robot.left.class]
  avail_moves.delete(Down) if Rock === robot.above
  p avail_moves
  move_values = avail_moves.zip(avail_moves.map {|d| robot.cell_at(d).value })
  best_move = move_values.sort_by {|p| p[1] }.last[0]
  command = DIRECTION_COMMANDS[best_move]
  map = map.command_robot(command).move_rocks
  if position == last_position
    commands << "A"
    break
  else
    commands << command
    last_position = position
  end
end

puts "!!!"
puts map
puts commands.join

