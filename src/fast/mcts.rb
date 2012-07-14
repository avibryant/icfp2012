require 'map'

class MonteCarloTree
  MOVES = ["L", "R", "U", "D", "A"]

  def initialize(root)
    @root = root
    @maps = {"" => root}
    @scores = Hash.new(0)
    @counts = Hash.new(0)
    @start_time = Time.new.to_f
    @best = root
    @completed = {}
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def iterate(max_depth)
    map = pick_map(@root)

    depth = 0
    until map.done? || depth > max_depth
      map = map.move(pick_move)
    end

    unless map.done?
      map = map.move("A")
    end

    if map.score > @best.score
        @best = map
        dump
    end

    @completed[map.moves] = true

    moves = map.moves
    (0...moves.size).to_a.reverse.each do |i|
      parent_moves = moves[0..i]
      if(children(parent_moves).all?{|m| @completed[m]})
        @completed[parent_moves] = true
      end
      @counts[parent_moves] += 1
      @scores[parent_moves] += map.score
    end
    @counts[""] += 1
    @scores[""] ++ map.score
  end

  def pick_move
    MOVES[rand(MOVES.size)]
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

  C = 1.0 / Math.sqrt(2.0)

  def best_child(map)
    scores = incomplete_children(map.moves).map do |moves|
      q = @scores[moves]
      n = @counts[moves]
      m = @counts[map.moves]
      s = (q.to_f / n.to_f) +
            (C * Math.sqrt(2 * Math.log(m) / n))
      [s, moves]
    end
    scores.sort!{|a,b| a[0] <=> b[0]}
    best_moves = scores[-1][1]
    @maps[best_moves]
  end

  def incomplete_children(moves)
    children(moves).reject{|m| @completed[m]}
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