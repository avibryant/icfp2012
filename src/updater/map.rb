require '../ext/fast_update'

class Cell
  def initialize(map, x, y)
    @map, @x, @y = map, x, y
  end

  def x
    @x
  end

  def y
    @y
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

  def update_metadata(direction, metadata)
  end

  def update_metadata_rocks(metadata)
  end
end

class Wall < Cell
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
    if @map.lambdas_gone && (Robot === cell_at(direction.opposite))
      metadata["InLift"] = true
    end
  end
end

class OpenLift < Lift
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
      metadata["HeatMap"] = nil
    else
      metadata["LambdasLeft"] = (metadata["LambdasLeft"] || 0).to_i + 1
    end
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
      Robot
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

  def self.parse(string)
    metadata = {}
    lines = string.split("\n")
    if i = lines.find_index("")
      lines[i+1..-1].each do |md|
        k,v = md.split
        metadata[k] = v
      end
      lines = lines[0...i]
    end

    cells = parse_lines(lines)

    Map.new(cells, metadata)
  end

  def self.parse_lines(lines)
    rows = lines.reverse.map do |r|
      classes = []
      r.each_char{|c| classes << CELL_CLASSES[c]}
      classes
    end
    maxSize = rows.map {|classes| classes.size}.max
    rows.map do |classes|
      (maxSize - classes.size).times {classes << Empty}
      classes
    end
  end

  def self.render(map)
    map.cells.reverse.map{|r| r.map{|c| render_cell(c)}.join}.join("\n") + 
    "\n\n" +
    map.metadata.select{|k,v| v != nil}.map{|k,v| k + " " + v.to_s}.join("\n") +
    "\nScore " + map.score.to_s
  end

  def self.render_cell(cell)
    CELL_CLASSES.each do |k,v|
      if v === cell
        return k
      end
    end
  end
end

$time = 0

class Map
  DIRECTION_CLASSES = {
    "U" => Up,
    "L" => Left,
    "D" => Down,
    "R" => Right
  }

  attr_reader :cells, :metadata

  def self.parse(string)
    Parser.parse(string)
  end

  def initialize(rows, metadata = {})
    @width = rows[0].size
    @cells = (0...rows.size).map do |y|
      line = rows[y]
      (0...line.size).map do |x|
        line[x].new(self, x, y)
      end
    end
    @metadata = metadata.clone
  end

  def lambdas_gone
    @metadata["LambdasLeft"].to_i == 0
  end

  def robot_distance_to_closest_lambda
    @cells.each do |r|
      r.each do |c|
        @robot = c if Robot === c
      end
    end
    md = heat_map[@robot.y][@robot.x]
    md == 10000 ? 0 : md
  end

  def heat_map
    return @heat_map if @heat_map != nil
    if @metadata["HeatMap"] != nil
      out = []
      row = []
      @metadata["HeatMap"].split(",").each_with_index do |c, i|
        row = [] if i % width == 0
        row << c.to_i
        out << row if i % width == width - 1
      end
      return out
    end
    lambda_heat_map = @cells.map do |r|
      r.map do |c|
        Lambda === c ? 0 : 10000
      end
    end
    lift_heat_map = @cells.map do |r|
      r.map do |c|
        Lift === c ? 0 : 10000
      end
    end
    while (lambda_heat_map != (heat_map_temp = next_heat_map(lambda_heat_map)))
      lambda_heat_map = heat_map_temp
    end

    while (lift_heat_map != (heat_map_temp = next_heat_map(lift_heat_map)))
      lift_heat_map = heat_map_temp
    end

    if lambda_heat_map.map{|r| r.min}.min == 10000
      @heat_map = lift_heat_map
    else
      @heat_map = lambda_heat_map
    end

    @heat_map
  end

  def next_heat_map(hm)
    out = []
    hm.each_with_index do |r, y|
      row = []
      r.each_with_index do |c, x|
        options = [c]
        penalty = Rock === self[x,y] ? 3 : 1
        if !(Wall === self[x, y])
          options << hm[y][x - 1] + penalty if (x > 0)
          options << hm[y][x + 1] + penalty if (x + 1 < width)
          options << hm[y - 1][x] + penalty if (y > 0)
          options << hm[y + 1][x] + penalty if (y + 1 < height)
        end
        row << options.min
      end
      out << row
    end
    out
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
      c.move_rocks
      }}
      $time += (Time.new.to_f - t1)
    end
    Map.new(cells, metadata)
  end

  def height
    @cells.size
  end

  def width
    @cells[0].size
  end

  def move_robot(direction)
    metadata = @metadata.clone
    metadata['HeatMap'] = heat_map.flatten.join(",")
    metadata['LambdasLeft'] = 0
    cells = @cells.map{|r| r.map{|c|
        dir = DIRECTION_CLASSES[direction]
        c.update_metadata(dir, metadata)
        c.move_robot(dir)
    }}
    Map.new(cells, metadata)
  end

  def command_robot(command)
    if command == "A"
      metadata = @metadata.clone
      metadata['HeatMap'] = heat_map.flatten.join(",")
      metadata["Aborted"] = true
      metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
      Map.new(cells.map{|r| r.map{|c| c.class}}, metadata)
    elsif command == "W"
      metadata = @metadata.clone
      metadata['HeatMap'] = heat_map.flatten.join(",")
      metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
      Map.new(cells.map{|r| r.map{|c| c.class}}, metadata)
    else
      move_robot(command)
    end
  end

  def score
    s = 0
    if(l = @metadata["Lambdas"])
      s += l.to_i * 25
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

  def is_done?
    @metadata["InLift"] || @metadata["Aborted"] || @metadata["Dead"]
  end
end
