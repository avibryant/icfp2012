require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R", "W", "A"]

  attr_reader :leaves, :leaves_considered

  def initialize(map)
    @leaves = [map]
    @leaves_considered = 0
    @start_time = Time.new.to_f
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def iterate
    new_leaves = []
    @leaves.each do |leaf|
      if leaf.done?
        new_leaves << leaf
      else
        DIRECTIONS.each do |dir|
          new_leaves << leaf.move(dir)
          @leaves_considered += 1
       end
      end
    end
    @leaves = new_leaves
  end

  def top(n)
    sorted_leaves = @leaves.shuffle.sort{|a,b| a.score <=> b.score}
    best_done = sorted_leaves.reverse.find{|l| l.done?}
    sorted_leaves.reject!{|l| l.done? && l != best_done}
    if(sorted_leaves.size> n)
      sorted_leaves = sorted_leaves[-1 * n .. -1]
    end
    sorted_leaves
  end

  def prune(n)
    @leaves = top(n)
  end
end

map = FastMap.new(STDIN.read.split("\n"))
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
  best = tree.top(1)[0]
  puts "Best score: #{best.score}"
  puts "Best moves: #{best.moves}"
  puts "Leaves: #{tree.leaves.size}"
  puts "Leaves considered: #{tree.leaves_considered}"
  puts "Total time elapsed: #{tree.time_elapsed}"
end