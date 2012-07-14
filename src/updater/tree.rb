require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R", "W", "A"]

  attr_reader :leaves, :move_robot_time, :move_rocks_time, :score_time, :sort_time, :leaves_considered

  def initialize(map)
    @leaves = {"" => map}
    @move_robot_time = 0
    @move_rocks_time = 0
    @score_time = 0
    @sort_time = 0
    @leaves_considered = 0
  end

  def iterate
    new_leaves = {}
    @leaves.each do |moves, leaf|
      if leaf.is_done?
        new_leaves[moves] = leaf
      else
        DIRECTIONS.each do |dir|
          t1 = Time.new.to_f
          mx = leaf.command_robot(dir)
          t2 = Time.new.to_f
          mr = mx.move_rocks
          t3 = Time.new.to_f
          new_leaves[moves + dir] = mr
          @leaves_considered += 1
          @move_robot_time += (t2 - t1)
          @move_rocks_time += (t3 - t2)
       end
      end
    end
    @leaves = new_leaves
  end

  def top(n)
    scores = {}
    t1 = Time.new.to_f
    @leaves.each do |moves, leaf|
      scores[moves] = leaf.score
    end
    t2 = Time.new.to_f

    sorted_moves = scores.keys.shuffle.sort{|a,b| scores[a] <=> scores[b]}
    best_done = sorted_moves.reverse.find{|m| @leaves[m].is_done?}
    sorted_moves = sorted_moves.reject{|m| @leaves[m].is_done? && m != best_done}
    if(sorted_moves.size> n)
      sorted_moves = sorted_moves[-1 * n .. -1]
    end
    t3 = Time.new.to_f

    @score_time += (t2 - t1)
    @sort_time += (t3 - t2)
    sorted_moves.map{|m| [m, scores[m]]}
  end

  def prune(n)
# the below didn't work well but leaving it in for posterity
#    best_score = top(1)[0][1]
#    if(best_score && best_score > 0)
#      n *= (1.0 / Math.log(best_score))
#      n = n.to_i
#    end
    pruned = {}
    top(n).each do |k,s|
      pruned[k] = @leaves[k]
    end
    @leaves = pruned
  end 

  def best_leaf
    best_score = -100
    best_leaf = nil
    @leaves.each do |moves, leaf|
      if leaf.score > best_score
        best_score = leaf.score
        best_leaf = [moves, leaf]
      end
    end
    best_leaf
  end
end

map = Map.parse(STDIN.read)
tree = Tree.new(map)
iterations = ARGV.shift.to_i
prune = ARGV.shift.to_i
iterate_time = 0
iterations.times do |i|
  t1 = Time.new.to_f
  tree.iterate
  iterate_time += (Time.new.to_f - t1)
  tree.prune(prune)
  puts "Iteration #{i+1}"
  puts "Leaves: #{tree.leaves.size}"
  puts "Leaves considered: #{tree.leaves_considered}"
  moves, score = tree.top(1)[0]
  puts "Best score: #{score}"
  puts "Best moves: #{moves}"
  puts "Best lambdas: #{tree.leaves[moves].lambdas}"
  puts "Move robot time: #{tree.move_robot_time}"
  puts "Move rocks time: #{tree.move_rocks_time}"
  puts "Extra iterate time: #{iterate_time - tree.move_robot_time - tree.move_rocks_time}"
  puts $time
end