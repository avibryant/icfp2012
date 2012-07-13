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
end

class Wall < Cell
end

class Lift < Cell
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
      (Rock == above.right && above.right.movingDownLeft)
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
    elsif Empty === cell_at(direction) || Earth === cell_at(direction)
      Empty
    elsif Rock === cell_at(direction) && Empty === cell_at(direction).cell_at(direction)
      Empty
    else
      Robot
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
    "R" => Robot
  }

  def self.parse(string)
    rows = string.split("\n").reverse.map do |r|
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

  def self.render(cells)
    cells.reverse.map{|r| r.map{|c| render_cell(c)}.join}.join("\n")
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

  def self.parse(string)
    self.new(Parser.parse(string))
  end

  def initialize(rows)
    @width = rows[0].size
    @cells = (0...rows.size).map do |y|
      line = rows[y]
      (0...line.size).map do |x|
        line[x].new(self, x, y)
      end
    end
  end

  def [](x,y)
    return nil if @cells[y] == nil
    @cells[y][x]
  end

  def to_s
    Parser.render(@cells)
  end

  def move_rocks
    Map.new(@cells.map{|r| r.map{|c| c.moveRocks}})
  end

  def height
    @cells.size
  end

  def move_robot(direction)
    Map.new(@cells.map{|r| r.map{|c| c.moveRobot(DIRECTION_CLASSES[direction])}})
  end
end


puts Map.parse("#####\n* *R*\n\\   *.").move_robot('L').to_s
