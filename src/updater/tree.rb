require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R", "W", "A"]

  attr_reader :leaves

  def initialize(map)
    @leaves = {"" => map}
  end

  def iterate
    new_leaves = {}
    @leaves.each do |moves, leaf|
      if leaf.is_done?
        new_leaves[moves] = leaf
      else
        DIRECTIONS.each do |dir|
          new_leaves[moves + dir] = leaf.command_robot(dir).move_rocks
       end
      end
    end
    @leaves = new_leaves
  end

  def top(n)
    scores = {}
    @leaves.each do |moves, leaf|
      scores[moves] = [leaf.score, -leaf.robot_distance_to_closest_lambda]
    end

    sorted_moves = scores.keys.shuffle.sort{|a,b| scores[a][0] + scores[a][1]*2 <=> scores[b][0] + scores[b][1]*2}
    best_done = sorted_moves.reverse.find{|m| @leaves[m].is_done?}
    sorted_moves = sorted_moves.reject{|m| @leaves[m].is_done? && m != best_done}
    if(sorted_moves.size> n)
      sorted_moves = sorted_moves[-1 * n .. -1]
    end
    sorted_moves.map{|m| [m, scores[m]]}.reverse
  end

  def prune(n)
    pruned = {}
    i = 0
    top(11 * n).each do |k,s|
      pruned[k] = @leaves[k] if (i < n) || (rand(10) == 0)
      i += 1
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
iterations.times do |i|
  tree.iterate
  tree.prune(prune)
  puts "Iteration #{i+1}"
  puts "Leaves: #{tree.leaves.size}"
  moves, score = tree.top(1)[0]
  puts "Best score: #{score[0]}"
  puts score[1]
  puts "Best moves: #{moves}"
end