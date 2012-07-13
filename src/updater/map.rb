class LambdaMap
  def mapString
    <<-STR
######
#. *R#
#  *.#
#\\ * #
L  .\\#
######
STR
  end

  def initialize
    populateMap
    @writeMap = @clone
  end

  def clone
    ClonedLambdaMap.new(@map)
  end

  def width
    @widthCache ||= @map.map {|row| row.length}.max
  end

  def to_s
    @map.reverse.inject(''){|str, row| str + "\n" + row}
  end

  def set(x,y,char)
    @map[y][x] = char
  end

  def populateMap
    @map = mapString.split("\n").reverse
  end

  def rocks
    ret = []
    @map.each_with_index do |row, y|
      row.chars.with_index(0).each do |c, x| 
        ret.push Rock.new(self,x,y) if c == '*'
      end
    end
    ret
  end

  def [](x,y)
    return '#' if @map[y] == nil
    @map[y][x] || ((x < 0 or x >= @width) ? '#' : ' ')
  end

  def updateRobot(move)
  end

  def updateRocks
    writeMap = clone
    rocks.each {|rock| rock.update(writeMap)}
    writeMap
  end

end

class ClonedLambdaMap < LambdaMap
  def initialize(map)
    @map = map.map {|row| row.clone}
  end
end

class Robot
  
end

class Rock
  def initialize (readMap, x, y)
    @readMap = readMap
    @x = x
    @y = y
  end
  
  def to_s
    "#{@x},#{@y}"
  end

  def s
    @readMap[@x, @y - 1]
  end

  def e
    @readMap[@x + 1, @y]
  end

  def w
    @readMap[@x - 1, @y]
  end

  def se
    @readMap[@x + 1, @y - 1]
  end

  def sw
    @readMap[@x - 1, @y - 1]
  end

  def update(writeMap)
    if s == ' '
      moveS(writeMap)
    elsif s == '*'
      if canFallE?
        moveSE(writeMap)
      elsif canFallW?
        moveSW(writeMap)
      end
    elsif s == '\\'
      if canFallE?
        moveSE(writeMap)
      end
    end
  end

  def canFallE?
    e == ' ' and se == ' '
  end

  def canFallW?
    w == ' ' and sw == ' '
  end

  def moveS(writeMap)
    writeMap.set(@x, @y, ' ')
    writeMap.set(@x, @y - 1, '*')
  end

  def moveSE(writeMap)
    writeMap.set(@x, @y, ' ')
    writeMap.set(@x + 1, @y - 1, '*')
  end

  def moveSW(writeMap)
    writeMap.set(@x, @y, ' ')
    writeMap.set(@x - 1, @y - 1, '*')
  end

end

map = LambdaMap.new()
puts map.updateRocks
