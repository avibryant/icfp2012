require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R", "W", "A"]

  attr_reader :best, :queue, :maps

  def initialize(map)
    @queue = [map]
    @maps = 1
    @start_time = Time.new.to_f
    @best = nil
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def iterate
    new_queue = []
    @queue.each do |map|
      DIRECTIONS.each do |dir|
        @maps += 1
        new_map = map.move(dir)
        if new_map.done?
          if !@best || new_map.score > @best.score
            @best = new_map
          end
        else 
          new_queue << new_map
        end
     end
    end
    @queue = new_queue
  end

  def prune(n)
    sorted_queue = @queue.shuffle.sort{|a,b| a.score <=> b.score}
    if(sorted_queue.size> n)
      @queue = sorted_queue[-1 * n .. -1]
    end
  end
end

map = FastMap.new(STDIN.read.split("\n"))
tree = Tree.new(map)
iterations = ARGV.shift.to_i
prune = ARGV.shift.to_i

iterations.times do |i|
  t1 = Time.new.to_f
  tree.iterate
  tree.prune(prune)
  puts "Iteration #{i+1}"
  if tree.best
    puts "Best score: #{tree.best.score}"
    puts "Best moves: #{tree.best.moves}"
  end
  puts "Queue size: #{tree.queue.size}"
  puts "Maps considered: #{tree.maps}"
  puts "Total time elapsed: #{tree.time_elapsed}"
end