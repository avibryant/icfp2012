require '../ext/fast_update'
require '../updater/map'

USE_ULTRA = ENV["ULTRA"]

class FastMap  
  def initialize(lines, state = nil, moves = "", lambdas = 0, total_lambdas = nil, robot = nil, lift = false, dead = false, aborted = false)
    @lines = lines
    @state = state
    @moves = moves
    @lambdas = lambdas
    @total_lambdas = total_lambdas || count("\\")
    @robot = robot || find("R")
    @lift = lift
    @dead = dead
    @aborted = aborted

    if !state && USE_ULTRA
      @lines, @state = FastUpdate.ultra_update(@lines, @state)
    end
  end

  def heatmap_value
    @heatmap[fixed_find('R').reverse]
  end

  def fixed_find(char)
    a = find(char)
    [@lines.size - a[0] - 1, a[1]]
  end

  def best_moves
    robot = fixed_find('R').reverse
    moves = []
    moves << ['U', @heatmap[[robot[0], robot[1] + 1]]]
    moves << ['L', @heatmap[[robot[0] - 1, robot[1]]]]
    moves << ['R', @heatmap[[robot[0] + 1, robot[1]]]]
    moves << ['D', @heatmap[[robot[0], robot[1] - 1]]]
    moves << ['W', 0]
    moves.sort{|a,b| b[1] <=> a[1]}.select{|a| a[1] > -10000}.map{|a| a[0] }
  end

  def lambdas
    @lambdas
  end
  
  def create_heatmap!
    m = Parser::parse(to_s)
    m.alt_score_cells!
    @heatmap = m.get_heatmap
  end

  def heatmap
    @heatmap
  end

  def set_heatmap(hm)
    @heatmap = hm
    return self
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
    self.class.new(lines2, state2, @moves + dir, @lambdas + lambdas, @total_lambdas, robot, lift, dead, aborted).set_heatmap(heatmap)
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

  def count(char)
    count = 0
    @lines.each do |line|
      line.each_char do |c|
        if(c == char)
          count += 1
        end
      end
    end
    count
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

  def abort_score
    return @abort_score if @abort_score
    
    if done?
      @abort_score = score
    else
      @abort_score = move("A").score
    end
    @abort_score
  end

  def progress
   (abort_score + (heatmap_value)).to_f / (@total_lambdas * 75)
  end

  def moves
    @moves
  end

  def total_lambdas
    @total_lambdas
  end
end

if __FILE__ == $0
  map = FastMap.new(STDIN.read.split("\n"))
  puts map.to_s

  if ARGV[0]
    ARGV[0].each_char do |m|
      puts m
      map = map.move(m)
      puts map.to_s
      map.create_heatmap!
      puts "Best moves: #{map.best_moves.join}"
    end
  else
    until map.done?
      map.create_heatmap!
      m = map.best_moves[0]
      map = map.move(m)
      puts m
      puts map.to_s
    end
  end
end