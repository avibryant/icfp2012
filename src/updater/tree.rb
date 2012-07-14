require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R"]

  attr_reader :leaves

  def initialize(map)
    @leaves = {"" => map}
  end

  def iterate
    new_leaves = {}
    @leaves.each do |moves, leaf|
      DIRECTIONS.each do |dir|
        new_leaves[moves + dir] = leaf.move_robot(dir).move_rocks
      end
    end
    @leaves = new_leaves
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
iterations.times do |i|
  tree.iterate
  puts "Iteration #{i+1}"
  puts "Leaves: #{tree.leaves.size}"
  moves, leaf = tree.best_leaf
  puts "Best score: #{leaf.score}"
  puts "Best moves: #{moves}"
end