require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

map = Map.parse(STDIN.read)

commands = []
last_position = nil

class Abort < StandardError; end

class RingBuffer
  def initialize(limit)
    @storage = []
    @limit = limit
  end

  def <<(value)
    @storage.shift if @storage.size > (@limit - 1)
    @storage << value
  end

  def member?(value)
    @storage.member?(value)
  end
end

last_2_moves = RingBuffer.new(2)
move_counts = Hash.new(0)

def available_moves_from(cell)
  avail_moves = DIRECTIONS.dup
  avail_moves.delete(Down) if Rock === cell.above
  move_values = avail_moves.zip(avail_moves.map {|d| cell.cell_at(d).value })
  move_values.reject! {|p| p[1] < 0 }
  move_values
end

def random_move_from(move_list)
  move_list[rand(move_list.size)][0]
end

begin
while !map.is_done?
  puts "---"
  map.score_cells!
  puts map
  puts commands.join
  position = map.metadata["RobotPosition"]
  robot = map[*position]

  move_values = available_moves_from(robot)

  raise Abort, "no valid moves" if move_values.empty?

  sorted_moves = move_values.sort_by {|p| -p[1] }
  best_move = (sorted_moves.shift)[0]
  # don't move into a spot where we already know no further moves will be available
  if available_moves_from(robot.cell_at(best_move)).empty?
    best_move = random_move_from(sorted_moves)
  end

  move_trace = [best_move, position]
  if last_2_moves.member?(move_trace) && move_counts[move_trace] > 2
    best_move = random_move_from(sorted_moves)
    move_trace = [best_move, position]
  end

  last_2_moves << move_trace
  move_counts[move_trace] += 1
  raise Abort, "loop detected" if last_2_moves.member?(move_trace) && move_counts[move_trace] > 2

  command = DIRECTION_COMMANDS[best_move]
  map = map.command_robot(command).move_rocks

  raise Abort, "move failed" if position == last_position

  commands << command
  last_position = position
end
rescue Abort => a
  puts "\nStopped: #{a.message}"
  p last_2_moves
  commands << "A"
end

puts "!!!"
puts map
puts commands.join
puts "!!!"
puts "Expected score: #{map.score}"

