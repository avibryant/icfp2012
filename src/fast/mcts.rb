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
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def time_since_last_dump
    Time.new.to_f - @last_dump
  end

  def iterate(max_depth)
    map = pick_map(@root)
 #   puts map.moves
    best = map

    depth = 0
    until map.done? || depth > max_depth
      map = move(map)
      if map.score_ratio > best.score_ratio
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

    moves = best.moves
    parents = [""] +
              (0...moves.size).map{|i| moves[0..i]} +
              (0...moves.size).map{|i| moves[0..i].delete("W")}
 
    parents.uniq.each do |p|
      @counts[p] += 1
      @scores[p] += best.score_ratio
      @squared_scores[p] += (best.score_ratio * best.score_ratio)
    end
 
    if time_since_last_dump > 1
      dump
    end
  end

  def move(map)
    @moves += 1
    if rand < 0.1
      map.move("W")
    else
      map.move(MOVES[rand(MOVES.size - 1)])
    end
  end

  def pick_map(map)
    until(map.done?)
      untried = untried_moves(map)
      if(untried.empty?)
        map = best_child(map)
      else
        tried = MOVES - untried
        if(tried != [] && tried != ["W"] && rand > 0.5)
         # puts "r"
          map = best_child(map)
        else
        #  puts "e"
          return expand(map, untried)
        end
      end
    end
    map
  end

  def expand(map, moves)
    move = moves[0]
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
  end

  def best
    @best
  end
end

# map = FastMap.new(STDIN.read.split("\n"))
# tree = MonteCarloTree.new(map)
# max_time = ARGV.shift.to_i

# while tree.time_elapsed < max_time
#   tree.iterate(map.total_lambdas * 5)
# end
