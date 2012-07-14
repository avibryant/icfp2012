require '../ext/fast_update'

class FastMap  
  def initialize(lines, moves = 0, lambdas = 0, robot = nil, lift = false, dead = false, aborted = false)
    @lines = lines
    @moves = moves
    @lambdas = lambdas
    @robot = robot || find("R")
    @lift = lift
    @dead = dead
    @aborted = aborted
  end

  DIR_MAP =
    {"L" => 0,
    "R" => 1,
    "U" => 2,
    "D" => 3}

  def move(dir)
    if done?
      self
    end

    if (dir == "W" || dir == "A")
      lines, lambdas, robot, lift = @lines, 0, @pos, @lift
      if(dir == "A")
        aborted = true
        moves = 0
      else
        moves = 1
      end
    else
      lines, lambdas, robot = FastUpdate.move(@lines, @robot[0], @robot[1], DIR_MAP[dir]) 
      if lambdas == -1
        lambdas = 0
        lift = true
      else
        lift = @lift
      end
      aborted = @aborted
      moves = 1
    end
    lines2, dead = FastUpdate.update(lines)
    self.class.new(lines2, @moves + moves, @lambdas + lambdas, robot, lift, dead>0, aborted)
  end

  def find(char)
    @lines.each_with_index do |line, row|
      (0...line.size).each do |col|
        if(line[col] == char[0])
          return [row, col]
        end
      end
    end
  end

  def to_s
    (@lines + ["\n", "Score #{score}\nStatus (#{@lift},#{@dead},#{@aborted})", "Lambdas #{@lambdas}"]).join("\n")
  end

  def done?
    @lift || @dead || @aborted
  end

  def score
    s = @lambdas * 25
    if @aborted
      s *= 2
    end

    if @lift
      s *= 3
    end
    s - @moves
  end
end

if __FILE__ == $0
  map = FastMap.new(STDIN.read.split("\n"))
  puts map.to_s

  ARGV[0].each_char do |m|
    puts m
    map = map.move(m)
    puts map.to_s
  end
end