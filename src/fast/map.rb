require '../ext/fast_update'

USE_ULTRA = ENV["ULTRA"]

class FastMap  
  def initialize(lines, state = nil, moves = "", lambdas = 0, robot = nil, lift = false, dead = false, aborted = false)
    @lines = lines
    @state = state
    @moves = moves
    @lambdas = lambdas
    @robot = robot || find("R")
    @lift = lift
    @dead = dead
    @aborted = aborted

    if !state && USE_ULTRA
      @lines, @state = FastUpdate.ultra_update(@lines, @state)
    end
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
      lines, lambdas, robot, lift, state = @lines, 0, @pos, @lift, @state
      if(dir == "A")
        aborted = true
      end
    else
      if USE_ULTRA
        lines, lambdas, robot, state = FastUpdate.ultra_move(@lines, @robot[0], @robot[1], DIR_MAP[dir], @state)
      else
        lines, lambdas, robot = FastUpdate.move(@lines, @robot[0], @robot[1], DIR_MAP[dir])
      end

      if lambdas == -1
        lambdas = 0
        lift = true
      else
        lift = @lift
      end
      aborted = @aborted
      moves = 1
    end

    if USE_ULTRA
      lines2, state2, dead = FastUpdate.ultra_update(lines, state)
    else
      lines2, dead = FastUpdate.update(lines)
      state2 = nil
    end
    self.class.new(lines2, state2, @moves + dir, @lambdas + lambdas, robot, lift, dead, aborted)
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
    return @score if @score

    @score = @lambdas * 25
    if @aborted
      @score *= 2
    end

    if @lift
      @score *= 3
    end
    @score -= @moves.size
    if @moves[-1] == ?A
      @score += 1
    end
    @score
  end

  def moves
    @moves
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