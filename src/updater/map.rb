require '../ext/fast_update'

class Cell
  attr_reader :x, :y, :char

  def initialize(map, x, y, char)
    @map, @x, @y, @char = map, x, y, char
  end

  def below
    @map[@x, @y - 1]
  end

  def above
    @map[@x, @y + 1]
  end

  def right
    @map[@x + 1, @y]
  end

  def left
    @map[@x - 1, @y]
  end

  def cell_at(direction)
    direction.cell_at(self)
  end

  def move_rocks
    self.class
  end

  def move_robot(direction)
    self.class
  end

  # update map metadata after move stage is complete
  def update_metadata(direction, metadata)
  end

  # update map metadata after rock movement is calculated
  def update_metadata_rocks(metadata)
  end

  # update map metadata just after parsing/creation of the map
  def update_initial_metadata(metadata)
  end

  def neighbors
    [above, right, below, left].compact
  end

  def get_heatmap_value(current, distance)
    if current.nil?
      [-1, (Lambda::VALUE - distance**2)].max
    else
      best_neighbor = neighbors.collect {|c| c.value }.max
      (best_neighbor || 0) - 1
    end
  end

  def value
    if hm = @map.metadata["HeatMap"]
      hm[[x, y]]
    else
      0
    end
  end

  def underwater?
    @map.metadata["Water"].to_i > y
  end

  def to_s
    "#{self.class}@(#{x},#{y})"
  end
end

class Wall < Cell
  def get_heatmap_value(current, distance)
    -1
  end
end

class Lift < Cell
  def move_robot(direction)
    if !@map.lambdas_gone
      Lift
    elsif cell_at(direction.opposite) == nil
      Lift
    elsif Robot === cell_at(direction.opposite)
      Robot
    else
      Lift
    end
  end

  def update_metadata(direction, metadata)
    if @map.lambdas_gone
      metadata["Replacements"] << [[x, y], [nil, OpenLift]]

      if Robot === cell_at(direction.opposite)
        metadata["InLift"] = true
      end
    end
  end

  def update_initial_metadata(metadata)
    (metadata["LiftPositions"] ||= []) << [x, y]
  end

  def get_heatmap_value(current, distance)
    -1
  end
end

class OpenLift < Lift
  VALUE = 99

  def get_heatmap_value(current, distance)
    if underwater? then -1 else VALUE end
  end
end

class Earth < Cell
  def move_robot(direction)
    if cell_at(direction.opposite) == nil
      Earth
    elsif Robot === cell_at(direction.opposite)
      Robot
    else
      Earth
    end
  end
end

class Lambda < Cell
  VALUE = 25

  def move_robot(direction)
    if cell_at(direction.opposite) == nil
      Lambda
    elsif Robot === cell_at(direction.opposite)
      Robot
    else
      Lambda
    end
  end

  def update_metadata(direction, metadata)
    if(Robot === cell_at(direction.opposite))
      metadata["Lambdas"] = (metadata["Lambdas"] || 0).to_i + 1
    else
      metadata["LambdasLeft"] = (metadata["LambdasLeft"] || 0).to_i + 1
    end
  end

  def update_initial_metadata(metadata)
    (metadata["LambdaPositions"] ||= []) << [x, y]
  end

  def get_heatmap_value(current, distance)
    if underwater? then -1 else VALUE end
  end
end

class Rock < Cell
  def move_rocks
    if moving_down || moving_down_right || moving_down_left
      Empty
    else
      Rock
    end
  end

  def moving_down
    Empty === below
  end

  def moving_down_right
    (Rock === below || Lambda === below) &&
        Empty === right &&
        Empty === right.below
  end

  def moving_down_left
    !moving_down_right &&
      Rock === below &&
      Empty === left &&
      Empty === left.below
  end

  def move_robot(direction)
    if (Right == direction || Left == direction) && Robot === cell_at(direction.opposite) && Empty === cell_at(direction)
      Robot
    else
      Rock
    end
  end

  def get_heatmap_value(current, distance)
    -1
  end
end

class DeadRobot < Cell

end

class Empty < Cell
  def move_robot(direction)
    if cell_at(direction.opposite) == nil
      Empty
    elsif Robot === cell_at(direction.opposite)
      Robot
    elsif (Right == direction || Left == direction) && Rock === cell_at(direction.opposite) && Robot === cell_at(direction.opposite).cell_at(direction.opposite)
      Rock
    else
      Empty
    end
  end

  def move_rocks
    if above == nil
      Empty
    elsif Rock === above ||
      (Rock === above.left && above.left.moving_down_right) ||
      (Rock === above.right && above.right.moving_down_left)
      Rock
    else
      Empty
    end
  end
end

class Robot < Cell
  def move_robot(direction)
    if cell_at(direction) == nil
      Robot
    elsif Empty === cell_at(direction) || Earth === cell_at(direction) || Lambda === cell_at(direction)
      Empty
    elsif (Right == direction || Left == direction) && Rock === cell_at(direction) && Empty === cell_at(direction).cell_at(direction)
      Empty
    elsif @map.lambdas_gone && Lift === cell_at(direction)
      Empty
    else
      Robot
    end
  end

  def move_rocks
    if above == nil || above.above == nil
      Robot
    elsif (Rock === above.above && above.above.moving_down) || (Rock === above.above.left && above.above.left.moving_down_right) ||
      (Rock === above.above.right && above.above.right.moving_down_left)
      Earth
    else
      Robot
    end
  end

  def update_metadata(direction, metadata)
    metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
  end

  def update_metadata_rocks(metadata)
    if above != nil && above.above != nil
      if (Rock === above.above && above.above.moving_down) || (Rock === above.above.left && above.above.left.moving_down_right) ||
        (Rock === above.above.right && above.above.right.moving_down_left)
        metadata["Dead"] = true
      end
    end

    flood_rate = metadata["Flooding"].to_i
    if flood_rate > 0
      water_level = (metadata["Moves"] / flood_rate) + 1
      metadata["Water"] = water_level
      if underwater?
        metadata["TimeUnderWater"] += 1
      else
        metadata["TimeUnderWater"] = 0
      end

      if metadata["TimeUnderWater"] > metadata["Waterproof"].to_i
        metadata["Dead"] = true
      end
    end
  end

  def update_metadata_water(metadata)
  end

  def update_initial_metadata(metadata)
    metadata["RobotPosition"] = [x, y]
  end
end

class Trampoline < Cell
  def target
    target_name = @map.metadata["Trampolines"][char]
    target_pos = @map.metadata["TargetPositions"][target_name]
    @map[*target_pos]
  end

  def get_heatmap_value(current, distance)
    dst = target
    if Target === dst
      dst.get_heatmap_value(current, distance, true)
    else
      super
    end
  end

  # This is kind of awful; better ideas welcomed
  def update_metadata(dir, metadata)
    if Robot === cell_at(dir.opposite)
      # Tile will be gone after this move, so make sure the target gets the robot
      # and any other trampolines leading to it are removed
      dst = target
      #puts "Jumping from #{char}@(#{x},#{y}) -> #{dst.char}@(#{dst.x},#{dst.y})"

      robot = @map[*@map.metadata["RobotPosition"]]

      replace = [
        [[dst.x, dst.y], [nil, Robot]],
        [[robot.x, robot.y], [nil, Empty]]
      ]

      @map.find_trampolines_to(dst.char).each do |t|
        pos = metadata["TrampolinePositions"][t]
        replace << [pos, [nil, Empty]]
      end

      metadata["Replacements"] += replace
    end
  end

  def update_initial_metadata(metadata)
    (metadata["TrampolinePositions"] ||= {})[char] = [x, y]
  end

  def move_robot(direction)
    if Robot === cell_at(direction.opposite)
      Empty
    else
      Trampoline
    end
  end
end

class Target < Cell
  def get_heatmap_value(current, distance, passthru=false)
    passthru ? super(current, distance) : -1
  end

  def update_initial_metadata(metadata)
    (metadata["TargetPositions"] ||= {})[char] = [x, y]
  end
end

class Direction
end

class Up < Direction
  def self.opposite
    Down
  end
  def self.cell_at(cell)
    cell.above
  end
end

class Down < Direction
  def self.opposite
    Up
  end
  def self.cell_at(cell)
    cell.below
  end
end

class Left < Direction
  def self.opposite
    Right
  end
  def self.cell_at(cell)
    cell.left
  end
end

class Right < Direction
  def self.opposite
    Left
  end
  def self.cell_at(cell)
    cell.right
  end
end

class Parser
  CELL_CLASSES = {
    "#" => Wall,
    "*" => Rock,
    "L" => Lift,
    "O" => OpenLift,
    "." => Earth,
    "\\" => Lambda,
    " " => Empty,
    "R" => Robot,
    "D" => DeadRobot
  }

  CELL_CHARACTERS = CELL_CLASSES.invert

  ("A".."I").each {|c| CELL_CLASSES[c] = Trampoline }
  ("1".."9").each {|i| CELL_CLASSES[i] = Target }

  def self.parse(string)
    metadata = {}
    lines = string.split("\n")
    if i = lines.find_index("")
      lines[i+1..-1].each do |md|
        k,v = md.split($;, 2)
        if k == "Trampoline"
          parse_trampoline(k, v, metadata)
        else
          metadata[k] = v
        end
      end
      lines = lines[0...i]
    end

    cells = parse_lines(lines)

    Map.new(cells, metadata)
  end

  def self.parse_trampoline(k, v, metadata)
    trampolines = (metadata["Trampolines"] ||= {})
    src, dst = v.split(" targets ")
    trampolines[src] = dst
  end

  def self.parse_lines(lines)
    rows = lines.reverse.map do |r|
      cols = []
      r.each_char{|c| cols << [c, CELL_CLASSES[c]]}
      cols
    end
    maxSize = rows.map {|cols| cols.size}.max
    rows.map do |cols|
      (maxSize - cols.size).times {cols << [" ", Empty]}
      cols
    end
  end

  def self.render(map)
    cell_str = map.cells.reverse.map {|r| r.map{|c| render_cell(c)}.join}.join("\n")
    metadata = map.metadata.keys.select {|k| !Map::HIDDEN_METADATA.member?(k) }.map do |k|
      v = map.metadata[k]
      "#{k} #{v.inspect}"
    end
    metadata_str = metadata.join("\n")
    #trampolines = metadata["Trampolines"]
    #trampoline_str = trampolines.map {|k, v| "Trampoline #{k} targets #{v}" }
    cell_str + "\n\n" + metadata_str + "\nScore #{map.score}"
  end

  def self.render_cell(cell)
    cell.char
#        s = "%02i" % cell.value
#        return "#{k}:#{s} "
  end
end

$time = 0

class Map
  DIRECTION_CLASSES = {
    "U" => Up,
    "L" => Left,
    "D" => Down,
    "R" => Right
  }.freeze

  DEFAULT_METADATA = {
    "Water" => 0,
    "Flooding" => 0,
    "Waterproof" => 10,
    "TimeUnderWater" => 0,
    "HeatMap" => {},
    "TrampolinePositions" => {},
    "TargetPositions" => {}
  }.freeze

  HIDDEN_METADATA = %w[
    HeatMap LambdaPositions TrampolinePositions TargetPositions
  ]

  attr_reader :cells, :metadata, :width, :height

  def self.parse(string)
    Parser.parse(string)
  end

  def initialize(rows, metadata=nil, moves="")
    @metadata = DEFAULT_METADATA.clone.merge(metadata)
    @width = rows[0].size
    @cells = (0...rows.size).map do |y|
      line = rows[y]
      (0...line.size).map do |x|
        char, klass = line[x]
        char ||= Parser::CELL_CHARACTERS[klass]
        cell = klass.new(self, x, y, char)
        cell.update_initial_metadata(@metadata)
        cell
      end
    end
    @height = @cells.size
    @moves = moves
  end

  def lambdas_gone
    @metadata["LambdasLeft"].to_s == "0"
  end

  def find_trampolines_to(target)
    trampolines = @metadata["Trampolines"]
    trampolines.keys.select {|k| trampolines[k] == target }
  end

  def [](x,y)
    return nil if @cells[y] == nil
    @cells[y][x]
  end

  def to_s
    Parser.render(self)
  end

  def move_rocks
    metadata = @metadata.clone

    if ENV["FAST"]
      old_lines = @cells.reverse.map{|r| r.map{|c| Parser.render_cell(c)}.join}
      t1 = Time.new.to_f
      lines = FastUpdate.update(old_lines)
      $time += (Time.new.to_f - t1)
      cells = Parser.parse_lines(lines)
    else
      t1 = Time.new.to_f
      cells = @cells.map{|r| r.map{|c|
        c.update_metadata_rocks(metadata)
        new_c = c.move_rocks
        [Parser::CELL_CHARACTERS[new_c] || c.char, new_c]
      }}
      $time += (Time.new.to_f - t1)
    end
    Map.new(cells, metadata, moves)
  end

  def move_robot(direction)
    metadata = @metadata.clone

    previous_lambdas = metadata["LambdasLeft"]
    metadata["LambdasLeft"] = 0
    metadata["LambdaPositions"] = []
    metadata["LiftPositions"] = []
    metadata["Replacements"] = []

    cells = @cells.map{|r| r.map{|c|
        dir = DIRECTION_CLASSES[direction]
        c.update_metadata(dir, metadata)
        new_c = c.move_robot(dir)
        [Parser::CELL_CHARACTERS[new_c] || c.char, new_c]
    }}

    replace = metadata.delete("Replacements")
    replace.each do |pos, data|
      cells[pos[1]][pos[0]] = data
    end

    if previous_lambdas != metadata["LambdasLeft"]
      metadata["HeatMap"] = {}
    end

    Map.new(cells, metadata, moves + direction)
  end

  # This is a simple heatmap scoring algorithm; it initializes each cell to either
  # 99 (goal), -1 (obstacle), or the taxicab distance to the closest goal tile.
  # After that, subsequent calls will simply assign score each tile as either one of
  # the extrema (for goal/obstacle tiles) or max(neighbor scores) - 1.
  # After any lambda is collected (handled in #move_robot, above) the heatmap is
  # reset so new goal distances can be calculated.
  def score_cells!(entropy=nil)
    lambda_pos = @metadata["LambdaPositions"]
    if lambda_pos.empty?
      lambda_pos = @metadata["LiftPositions"]
    end

    heatmap = (@metadata["HeatMap"] ||= {})

    @cells.each do |row|
      row.each do |cell|
        min_distance = lambda_pos.map {|x, y| (cell.x - x).abs + (cell.y - y).abs }.min
        current = heatmap[[cell.x, cell.y]]
        value = cell.get_heatmap_value(current, min_distance)
        value += (rand(entropy + 2) - entropy - 1) if entropy
        heatmap[[cell.x, cell.y]] = value
      end
    end
  end

  def command_robot(command)
    if command == "A"
      metadata = @metadata.clone
      metadata["Aborted"] = true
      metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
      Map.new(cells.map{|r| r.map{|c| [c.char, c.class] }}, metadata, moves + command)
    elsif command == "W"
      metadata = @metadata.clone
      metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
      Map.new(cells.map{|r| r.map{|c| [c.char, c.class] }}, metadata, moves + command)
    else
      move_robot(command)
    end
  end

  def move(move)
    command_robot(move).move_rocks
  end

  def robot_value
    self.score_cells!
    x, y = @metadata["RobotPosition"]
    cell = self[x,y]
    if cell
      cell.value
    else
      -1
    end
  end

  def score
    s = 0
    if(l = @metadata["Lambdas"])
      s += l.to_i * Lambda::VALUE
    end
    if(@metadata["InLift"])
      s *= 3
    end
    if(@metadata["Aborted"])
      s *= 2
    end
    if(m = @metadata["Moves"])
      s -= m.to_i
    end
    s
  end

  def abort_score
    if is_done?
      score
    else
      move("A").score
    end
  end

  def is_done?
    @metadata["InLift"] || @metadata["Aborted"] || @metadata["Dead"]
  end

  def lambdas
    @metadata["Lambdas"]
  end

  def moves
    @moves
  end
end
