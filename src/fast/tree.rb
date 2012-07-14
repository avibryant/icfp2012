require 'map'

class Tree
  DIRECTIONS = ["U", "D", "L", "R", "W", "A"]

  attr_reader :best, :queue

  def initialize(map, &priority)
    @queue = {map => priority.call(map)}
    @start_time = Time.new.to_f
    @best = nil
    @priority = priority
  end

  def time_elapsed
    Time.new.to_f - @start_time
  end

  def iterate
    map = pick
    DIRECTIONS.each do |dir|
      new_map = map.move(dir)
      if new_map.done?
        if !@best || new_map.score > @best.score
          @best = new_map
        end
      else 
        @queue[new_map] = @priority.call(new_map)
      end
    end
    @queue.delete(map)
  end

  def pick
    priorities = @queue.values.sort
    @queue.keys.shuffle.find{|m| @queue[m] == priorities[-1]}
  end

  def prune(n)
    if @queue.size > (n*2)
      priorities = @queue.values.sort
      threshold = priorities[-1*n]
      @queue.reject!{|map,pri| pri < threshold}
    end
  end
end

map = FastMap.new(STDIN.read.split("\n"))
tree = Tree.new(map){|m| m.score}
prune = ARGV.shift.to_i

1_000_000.times do |i|
  t1 = Time.new.to_f
  tree.iterate
  tree.prune(prune)
  puts "Iteration #{i+1}"
  if tree.best
    puts "Best score: #{tree.best.score}"
    puts "Best moves: #{tree.best.moves}"
  end
  puts "Queue size: #{tree.queue.size}"
  puts "Total time elapsed: #{tree.time_elapsed}"
end