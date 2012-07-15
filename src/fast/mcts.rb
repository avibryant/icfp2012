require '../fast/map'

class MonteCarloTree
  MOVES = ["L", "D", "R", "U", "W"]

  def initialize(root)
    @root = root
    @maps = {"" => root}
    @scores = Hash.new(0)
    @squared_scores = Hash.new(0)
    @counts = Hash.new(0)
    @last_dump = @start_time = Time.new.to_f
    @best = root
    @moves = 0
    @iterations = 0
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def time_since_last_dump
    Time.new.to_f - @last_dump
  end

  def iterate(max_depth)
    @iterations += 1
    map = pick_map(@root)
    best = map

    depth = 0
    until map.done? || depth > max_depth
      map = move(map)
      if map.progress > best.progress
        best = map
      end
      depth += 1
    end

    if best.abort_score >= @best.score
      if best.done?
        @best = best
      else
        @best = best.move("A")
      end
      dump
    end

    parents = (0..best.moves.size).map{|i| best.moves[0...i]}
    s = best.progress
    s2 = s*s 
    parents.each do |p|
      @counts[p] += 1
      @scores[p] += s
      @squared_scores[p] += s2
    end
 
    if time_since_last_dump > 10
      dump
    end
  end

  def move(map)
    @moves += 1
    map.create_heatmap!
    best_moves = map.best_moves | MOVES
    n = best_moves.size
    mv = best_moves[n - 1 - Math.log(rand(Math::E ** n) + 1).to_i]
    m = map.move(mv)
    m
  end

  def pick_map(map)
    until(map.done?)
      untried = untried_moves(map)
      if(untried.empty?)
        map = best_child(map)
      else
        return expand(map, untried)
      end
    end
    map
  end

  def expand(map, moves)
    move = (map.best_moves & moves | moves)[0]
    next_map = map.move(move)
    @maps[next_map.moves] = next_map
    next_map
  end

  C = 1.0 / Math.sqrt(2.0)
  D = 1

  def best_child(map)
    scores = children(map.moves).shuffle.map do |moves|
      q = @scores[moves].to_f
      n = @counts[moves].to_f
      m = @counts[map.moves].to_f
      x = q / n
      s = x +
            (C * Math.sqrt(2.0 * Math.log(m) / n)) 
            + (Math.sqrt(
              (@squared_scores[moves].to_f - (n*x*x) + D) / n))
      [s, moves, q, n, m]
    end
    scores.sort!{|a,b| a[0] <=> b[0]}
    best_moves = scores[-1][1]
    @maps[best_moves]
  end

  def children(moves)
    MOVES.map{|m| moves + m}.select{|m| @maps.has_key?(m)}
  end

  def untried_moves(map)
    MOVES.reject{|m| @maps.has_key?(map.moves + m)}
  end

  def dump
    @last_dump = Time.new.to_f
    puts
    puts "Best score: #{@best.score}"
    puts "Best moves: #{@best.moves}"
    puts "Tree size: #{@maps.size}"
    puts "Time elapsed: #{time_elapsed}"
    puts "Moves/sec: #{(@moves.to_f / time_elapsed).to_i}"
    puts "Iterations/sec: #{(@iterations.to_f / time_elapsed).to_i}"
  end

  def best
    @best
  end
end

map = FastMap.new(STDIN.read.split("\n"))
map.create_heatmap!
tree = MonteCarloTree.new(map)
max_time = ARGV.shift.to_i
if max_time == 0
  max_time = 60
end
depth_ratio = ARGV.shift.to_i
if depth_ratio == 0
  depth_ratio = 5
end

while tree.time_elapsed < max_time
  tree.iterate(map.total_lambdas * depth_ratio)
end
