require '../ext/fast_update'

USE_ULTRA = ENV["ULTRA"]

class FastMap
  DEFAULT_METADATA = {
    "Water" => 0,
    "Flooding" => 0,
    "Waterproof" => 10,
    "TimeUnderWater" => 0,
    "HeatMap" => {},
    "TrampolinePositions" => {},
    "TargetPositions" => {}
  }.freeze

  def self.parse_trampoline(k, v, metadata)
    trampolines = (metadata["Trampolines"] ||= {})
    src, dst = v.split(" targets ")
    trampolines[src] = dst
  end

  def self.parse_metadata(lines)
    metadata = {}
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
    [lines, metadata]
  end

  def initialize(lines, state = nil, moves = "", lambdas = 0, total_lambdas = nil, robot = nil, lift = false, dead = false, aborted = false, metadata = nil)
    if metadata.nil?
      @lines, @metadata = FastMap.parse_metadata(lines)
    else
      @lines = lines
      @metadata = metadata
    end
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
    self.class.new(lines2, state2, @moves + dir, @lambdas + lambdas, @total_lambdas, robot, lift, dead, aborted, @metadata)
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

  def score_ratio
   abort_score.to_f / (@total_lambdas * 75)
  end

  def moves
    @moves
  end

  def target_positions
    pos = []
    @lines.each_with_index do |line, row|
      (0...line.size).each do |col|
        if(line[col] == ?O || line[col] == ?\\)
          pos << [row, col]
        end
      end
    end
    pos
  end

  def nearest_target
    return @nearest if @nearest

    targets = target_positions
    @nearest = nil
    nearest_dist = nil
    targets.each do |t|
      dist = distance_to(t)
      if !@nearest || dist < nearest_dist
        @nearest = t
        nearest_dist = dist
      end
    end
    @nearest
  end

  def distance_to(pos)
    (@robot[0] - pos[0]).abs + (@robot[1] - pos[1]).abs
  end

  def direction_to(pos)
    options = []
    options << "U" if(pos[0] < @robot[0])
    options << "D" if(pos[0] > @robot[0])
    options << "L" if(pos[1] < @robot[1])
    options << "R" if(pos[1] > @robot[1])
    options[rand(options.size)]
  end

  def total_lambdas
    @total_lambdas
  end
end

if __FILE__ == $0
  map = FastMap.new(STDIN.read.split("\n"))
  puts map.to_s

  ARGV[0].each_char do |m|
    puts m
    map = map.move(m)
    puts map.to_s
    puts "Direction to NT: #{map.direction_to(map.nearest_target)}"
  end
end
