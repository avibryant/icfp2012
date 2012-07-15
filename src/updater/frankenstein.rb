require '../fast/mcts'
require 'map'

DIRECTIONS = [Up, Right, Down, Left]
DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

MAX_ENTROPY = 10

map = Map.parse(ARGF.read)
map.alt_score_cells!

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

def available_moves_from(cell)
  avail_moves = DIRECTIONS.dup
  avail_moves.delete(Down) if Rock === cell.above
  avail_moves.reject! {|dir| ca = cell.cell_at(dir); Wall === ca || Rock === ca }
  move_values = avail_moves.zip(avail_moves.map {|d| cell.cell_at(d).value })
  move_values.sort_by {|p| -p[1] } #.reject {|p| p[1] < 0 }
end

def greedy_loop(map, commands)
  last_position = nil
  last_2_moves = RingBuffer.new(2)
  move_counts = Hash.new(0)
  current_entropy = 0
  original_map = map
  commands = commands[0 .. -4]

  commands.each {|command| map = map.command_robot(command).move_rocks}

  begin
  while !map.is_done?
    map.alt_score_cells!

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
      # [2, nil].each {|i| map.alt_score_cells!(i) }
      move_values = available_moves_from(robot)
      raise Abort, "no valid moves" if move_values.empty?
      best_move, best_score = move_values[0]
    end

    if last_2_moves.member?(move_trace) && move_counts[move_trace] > 2
      raise Abort, "loop detected"
    end

    last_2_moves << move_trace
    move_counts[move_trace] += 1

    puts ">>> #{best_move} -> #{robot.cell_at(best_move)}"
    command = DIRECTION_COMMANDS[best_move]
    new_map = map.command_robot(command).move_rocks

    puts map
    puts commands.join

    raise Abort, "move failed" if position == last_position
    raise Abort, "fatal move" if new_map.metadata["Dead"]

    map = new_map
    commands << command
    last_position = position
  end
  rescue Abort => a
    puts "\n!!! Stopped: #{a.message}"
    commands << "A"
    commands = get_commands_from_tree(original_map, commands)
  end
  return original_map, commands
end

def get_commands_from_tree(original_map, commands)
  mcts_map = FastMap.new(original_map.to_s.split("\n"))
  commands[0 .. -10].each do |a|
    mcts_map = mcts_map.move(a)
  end
  tree = MonteCarloTree.new(mcts_map)
  max_depth = 25
  max_time = 20
  while tree.time_elapsed < max_time
    tree.iterate(max_depth)
  end
  tree.best.moves.chars.to_a
end

commands = [] #get_commands_from_tree(map, [])
8.times {|n|
 map, commands = greedy_loop(map, commands) 
}

commands.each {|command| map = map.command_robot(command).move_rocks}

puts "\n==="
puts map
puts
puts commands.join
puts "Expected score: #{map.score}"
puts "#{map.score}\t#{commands.join}"

