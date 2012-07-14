class Cell
  def initialize(map, x, y)
    @map, @x, @y = map, x, y
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

  def moveRocks
    self.class
  end

  def moveRobot(direction)
    self.class
  end

  def updateMetadata(direction, metadata)
  end

  def updateMetadataRocks(metadata)
  end
end

class Wall < Cell
end

class Lift < Cell
  def moveRobot(direction)
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

  def updateMetadata(direction, metadata)
    if @map.lambdas_gone && (Robot === cell_at(direction.opposite))
      metadata["InLift"] = true
    end
  end
end

class Earth < Cell
  def moveRobot(direction)
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
  def moveRobot(direction)
    if cell_at(direction.opposite) == nil
      Lambda
    elsif Robot === cell_at(direction.opposite) 
      Robot
    else
      Lambda
    end
  end

  def updateMetadata(direction, metadata)
    if(Robot === cell_at(direction.opposite))
      metadata["Lambdas"] = (metadata["Lambdas"] || 0).to_i + 1
    else
      metadata["LambdasLeft"] = (metadata["LambdasLeft"] || 0).to_i + 1
    end
  end
end

class Rock < Cell
  def moveRocks  
    if movingDown || movingDownRight || movingDownLeft
      Empty
    else
      Rock
    end
  end

  def movingDown
    Empty === below
  end

  def movingDownRight
    (Rock === below || Lambda === below) &&
        Empty === right &&
        Empty === right.below
  end

  def movingDownLeft
    !movingDownRight && 
      Rock === below &&
      Empty === left &&
      Empty === left.below
  end

  def moveRobot(direction)
    if Robot === cell_at(direction.opposite) && Empty === cell_at(direction)
      Robot
    else
      Rock
    end
  end
end

class DeadRobot < Cell

end

class Empty < Cell
  def moveRobot(direction)
    if cell_at(direction.opposite) == nil
      Empty
    elsif Robot === cell_at(direction.opposite) 
      Robot
    elsif Rock === cell_at(direction.opposite) && Robot === cell_at(direction.opposite).cell_at(direction.opposite)
      Rock
    else
      Empty
    end
  end

  def moveRocks
    if above == nil
      Empty
    elsif Rock === above ||
      (Rock === above.left && above.left.movingDownRight) ||
      (Rock === above.right && above.right.movingDownLeft)
      Rock
    else
      Empty
    end
  end
end

class Robot < Cell
  def moveRobot(direction)
    if cell_at(direction) == nil
      Robot
    elsif Empty === cell_at(direction) || Earth === cell_at(direction) || Lambda === cell_at(direction)
      Empty
    elsif Rock === cell_at(direction) && Empty === cell_at(direction).cell_at(direction)
      Empty
    elsif @map.lambdas_gone && Lift === cell_at(direction)
      Empty
    else
      Robot
    end
  end
  def moveRocks
    if above == nil || above.above == nil
      Robot
    elsif (Rock === above.above && above.above.movingDown) || (Rock === above.above.left && above.above.left.movingDownRight) ||
      (Rock === above.above.right && above.above.right.movingDownLeft)
      Earth
    else
      Robot
    end
  end

  def updateMetadata(direction, metadata)
    metadata["Moves"] = (metadata["Moves"] || 0).to_i + 1
  end

  def updateMetadataRocks(metadata)
    if above != nil && above.above != nil
      if (Rock === above.above && above.above.movingDown) || (Rock === above.above.left && above.above.left.movingDownRight) ||
        (Rock === above.above.right && above.above.right.movingDownLeft)
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

    rows = lines.reverse.map do |r|
      classes = []
      r.each_char{|c| classes << CELL_CLASSES[c]}
      classes
    end
    maxSize = rows.map {|classes| classes.size}.max
    cells = rows.map do |classes|
      (maxSize - classes.size).times {classes << Empty}
      classes
    end

    Map.new(cells, metadata)
  end

  def self.render(map)
    map.cells.reverse.map{|r| r.map{|c| render_cell(c)}.join}.join("\n") + 
    "\n\n" +
    map.metadata.map{|k,v| k + " " + v.to_s}.join("\n")
  end

  def self.render_cell(cell)
    CELL_CLASSES.each do |k,v|
      if v === cell
        return k
      end
    end
  end
end

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
    @metadata = metadata
  end

  def lambdas_gone
    @metadata["LambdasLeft"] == "0"
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
    cells = @cells.map{|r| r.map{|c|
      c.updateMetadataRocks(metadata)
      c.moveRocks
    }}
    Map.new(cells, metadata)
  end

  def height
    @cells.size
  end

  def move_robot(direction)
    metadata = @metadata.clone
    metadata['LambdasLeft'] = 0
    cells = @cells.map{|r| r.map{|c|
        dir = DIRECTION_CLASSES[direction]
        c.updateMetadata(dir, metadata)
        c.moveRobot(dir)
    }}
    Map.new(cells, metadata)
  end

  def command_robot(command)
    if command == "A"
      metadata = @metadata.clone
      metadata["Aborted"] = true
      Map.new(cells.map{|r| r.map{|c| c.class}}, metadata)
    elsif command == "W"
      Map.new(cells.map{|r| r.map{|c| c.class}}, @metadata.clone)
    else
      move_robot(command)
    end
  end

  def score
    s = 0
    if(l = @metadata["Lambdas"])
      s += l.to_i * 25
    end
    if(@metadata["InLift"] == "true")
      s *= 3
    end
    if(@metadata["Aborted"] == "true")
      s *= 2
    end
    if(m = @metadata["Moves"])
      s -= m.to_i
    end
    s
  end
end
