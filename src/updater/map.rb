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

  def moveRocks
    self.class
  end
end

class Wall < Cell
end

class Lift < Cell
end

class Earth < Cell
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
end

class Empty < Cell
  def moveRocks
    if Rock === above ||
      (Rock === above.left && above.left.movingDownRight) ||
      (Rock == above.right && above.right.movingDownLeft)
      Rock
    else
      Empty
    end
  end
end

class Robot < Cell
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
    string.split("\n").reverse.map do |r|
      classes = []
      r.each_char{|c| classes << CELL_CLASSES[c]}
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
    @cells[y][x]
  end

  def to_s
    Parser.render(@cells)
  end

  def move_rocks
    Map.new(@cells.map{|r| r.map{|c| c.moveRocks}})
  end
end


puts Map.parse("#####\n* * *\n\\   *").move_rocks.to_s