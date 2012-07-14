require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

map = Map.parse(ARGF.read)
map.score_cells!

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
  move_values.sort_by {|p| -p[1] } #.reject {|p| p[1] < 0 }
end

begin
while !map.is_done?
  puts "---"
  map.score_cells!
  puts map
  puts commands.join

  metadata = map.metadata

  position = metadata["RobotPosition"]
  robot = map[*position]

  if robot.underwater? && metadata["TimeUnderWater"] >= (metadata["Waterproof"].to_i - 1)
    raise Abort, "going to drown"
  end

  move_values = available_moves_from(robot)
  raise Abort, "no valid moves" if move_values.empty?

  best_move, best_score = move_values.shift
  # if we're at a local maxima, recalculate cell scores
  if (best_score <= robot.value)
    map.score_cells!(5)
    map.score_cells!(1)
    map.score_cells!
    move_values = available_moves_from(robot)
    raise Abort, "no valid moves" if move_values.empty?
    best_move, best_score = move_values[0]
  end

  # don't move into a spot where we already know no further moves will be available
  #if available_moves_from(robot.cell_at(best_move)).empty?
  #  best_move = random_move_from(move_values)
  #end

  move_trace = [best_move, position]
  raise Abort, "loop detected" if last_2_moves.member?(move_trace) && move_counts[move_trace] > 2

  last_2_moves << move_trace
  move_counts[move_trace] += 1

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

