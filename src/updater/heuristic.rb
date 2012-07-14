require 'map'

class Heat

  def initialize(map)
    @map = map
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
  puts "Best score: #{score}"
  puts "Best moves: #{moves}"
end