require './map'

=begin

This is BDR, the "Big Dumb Robot"

It uses a simple greedy search algorithm along with a few simple heuristics
to quickly move towards the nearest Lambda or (if they've all been captured)
OpenLift tile in the map. (Actually, it doesn't know anything about tile
types, and instead dumbly moves to the highest-scored neighboring tile on each
iteration.

=end

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

class BDR
  DIRECTIONS = [Up, Right, Down, Left]
  DIRECTION_COMMANDS = Map::DIRECTION_CLASSES.invert

  class Abort < StandardError; end
  class WouldDrown < Abort; end
  class LoopDetected < Abort; end
  class NoValidMoves < Abort; end
  class WouldDie < Abort; end
  class MoveFailed < Abort; end

  attr_reader :map, :commands, :position, :error

  def initialize(map)
    @map = map
    @commands = []
    @position = nil
    @recent_moves = RingBuffer.new(2)
    @hit_counter = Hash.new(0)
  end

  def metadata
    @map.metadata
  end

  def step!
    last_position = position
    @map.score_cells!

    robot = map.robot
    position = metadata["RobotPosition"]

    raise WouldDrown if map.robot_drowning?

    move_values = available_moves_from(robot)
    raise NoValidMoves if move_values.empty?

    best_move, best_score = move_values.shift
    move_trace = [best_move, position]

    # If we're at a local maxima, recalculate cell scores with some entropy
    # (I call this "ghetto annealing")
    if (best_score <= robot.value) || @recent_moves.member?(move_trace)
      [2, nil].each {|i| @map.score_cells!(i) }
      move_values = available_moves_from(robot)
      raise NoValidMoves if move_values.empty?
      best_move, best_score = move_values[0]
    end

    if @recent_moves.member?(move_trace) && @hit_counter[move_trace] > 2
      raise LoopDetected, best_move
    end

    @recent_moves << move_trace
    @hit_counter[move_trace] += 1

    command = DIRECTION_COMMANDS[best_move]
    new_map = map.command_robot(command).move_rocks

    raise WouldDie, best_move if new_map.metadata["Dead"]
    raise MoveFailed, best_move if position == last_position

    @map = new_map
    @commands << command
    @position = position
  end

  def run!
    begin
      while !map.is_done?
        step!
        @on_step.call(self)
      end
    rescue Abort => a
      @error = a
      @commands << "A"
    end
  end

  def on_step(&block)
    @on_step = block
  end

  def available_moves_from(cell)
    avail_moves = DIRECTIONS.dup
    avail_moves.delete(Down) if Rock === cell.above
    avail_moves.reject! {|dir| [Wall, Rock].any? {|ct| ct === cell.cell_at(dir) } }
    move_values = avail_moves.zip(avail_moves.map {|d| cell.cell_at(d).value })
    move_values.sort_by {|p| -p[1] } #.reject {|p| p[1] < 0 }
  end
end

map = Parser.parse(ARGF.read)
bot = BDR.new(map)
bot.on_step {|b| puts "---"; puts b.map }
bot.run!
puts "\n==="
puts "Status: #{bot.error ? bot.error.class: "Okay!"}"
puts bot.map
puts
puts bot.commands.join
puts "Expected score: #{bot.map.score}"

