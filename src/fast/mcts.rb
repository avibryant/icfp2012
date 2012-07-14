require 'map'

class MonteCarloTree
  MOVES = ["L", "R", "U", "D", "W"]

  def initialize(root)
    @root = root
    @maps = {"" => root}
    @scores = Hash.new(0)
    @squared_scores = Hash.new(0)
    @counts = Hash.new(0)
    @start_time = Time.new.to_f
    @best = root
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def iterate(max_depth)
    map = pick_map(@root)
    best = map

    depth = 0
    until map.done? || depth > max_depth
      map = move(map)
      if map.abort_score > best.abort_score
        best = map
      end
      depth += 1
    end

    if best.abort_score > @best.score
        if best.done?
          @best = best
        else
          @best = best.move("A")
        end
        dump
    end

    moves = map.moves
    (0...moves.size).to_a.reverse.each do |i|
      parent_moves = moves[0..i]
      @counts[parent_moves] += 1
      @scores[parent_moves] += best.abort_score
      @squared_scores[parent_moves] += (best.abort_score * best.abort_score)
    end
    @counts[""] += 1
    @scores[""] += best.abort_score
    @squared_scores[""] += (best.abort_score * best.abort_score)
  end

  def move(map)
    if rand < 0.05
      map.move("W")
    else
      m = MOVES[rand(MOVES.size - 1)]
      map.move(m)
    end
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
    move = moves[rand(moves.size)]
    next_map = map.move(move)
    @maps[next_map.moves] = next_map
    next_map
  end

  C = 0.5
  D = 1000.0

  def best_child(map)
    scores = children(map.moves).shuffle.map do |moves|
      q = @scores[moves].to_f
      n = @counts[moves].to_f
      m = @counts[map.moves].to_f
      x = q / n
      s = x +
            (C * Math.sqrt(2.0 * Math.log(m) / n)) + 
            (Math.sqrt(
              (@squared_scores[moves].to_f - (n*x*x) + D) / n))
      [s, moves, q, n, m]
    end
    scores.sort!{|a,b| a[0] <=> b[0]}
    best_moves = scores[-1][1]
    @maps[best_moves]
  end

  def children(moves)
    MOVES.map{|m| moves + m}
  end

  def untried_moves(map)
    MOVES.reject{|m| @maps.has_key?(map.moves + m)}
  end

  def dump
    puts
    puts "Best score: #{@best.score}"
    puts "Best moves: #{@best.moves}"
    puts "Tree size: #{@maps.size}"
    puts "Time elapsed: #{time_elapsed}"
  end
end

map = FastMap.new(STDIN.read.split("\n"))
tree = MonteCarloTree.new(map)
max_depth = ARGV.shift.to_i
max_time = ARGV.shift.to_i

while tree.time_elapsed < max_time
  tree.iterate(max_depth)
end