require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

MAX_ENTROPY = 10

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

  def to_a
    @storage.dup
  end
end

last_2_moves = RingBuffer.new(2)
move_counts = Hash.new(0)
current_entropy = 0

def available_moves_from(cell)
  avail_moves = DIRECTIONS.dup
  avail_moves.delete(Down) if Rock === cell.above
  avail_moves.reject! {|dir| ca = cell.cell_at(dir); Wall === ca || Rock === ca }
  move_values = avail_moves.zip(avail_moves.map {|d| cell.cell_at(d).value })
  move_values.sort_by {|p| -p[1] } #.reject {|p| p[1] < 0 }
end

begin
while !map.is_done?
  map.score_cells!

  metadata = map.metadata

  position = metadata["RobotPosition"]
  robot = map[*position]

  if robot.underwater? && metadata["TimeUnderWater"] >= (metadata["Waterproof"].to_i - 1)
    raise Abort, "going to drown"
  end

  move_values = available_moves_from(robot)
  raise Abort, "no valid moves" if move_values.empty?

  best_move, best_score = move_values.shift
  move_trace = [best_move, position]

  # If we're at a local maxima, recalculate cell scores with some entropy
  # (I call this "ghetto annealing")
  # Do the same for loops
  if (best_score <= robot.value) || last_2_moves.member?(move_trace)
    [2, nil].each {|i| map.score_cells!(i) }
    move_values = available_moves_from(robot)
    raise Abort, "no valid moves" if move_values.empty?
    best_move, best_score = move_values[0]
  end

  if last_2_moves.member?(move_trace) && move_counts[move_trace] > 2
    raise Abort, "loop detected"
  end

  last_2_moves << move_trace
  move_counts[move_trace] += 1

  puts ">>> #{best_move} -> #{robot.cell_at(best_move)} [#{best_score}]"
  command = DIRECTION_COMMANDS[best_move]
  new_map = map.command_robot(command).move_rocks


  raise Abort, "move failed" if position == last_position
  raise Abort, "fatal move" if new_map.metadata["Dead"]

  map = new_map
  commands << command
  last_position = position

  puts map
  puts commands.join
  puts
end
rescue Abort => a
  puts "\n!!! Stopped: #{a.message}"
  commands << "A"
end

puts "\n==="
puts map
puts
puts commands.join
puts "Expected score: #{map.score}"

