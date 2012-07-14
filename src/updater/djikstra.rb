require 'set'
require 'map'

class Djikstra
  def initialize(map, dest)
    @map = map.clone
    @destination = dest.clone
    @unvisited = Set.new
    0.upto(map.height - 1).each{|i| 0.upto(map.width - 1).each{|j| @unvisited << [i,j]}}
    @distance = map.height.times.map{ map.width.times.map{ 1e6 } }
    @unvisited.delete(dest)
    @distance[dest[0]][dest[1]] = 0
  end

  def best_unvisited
    best_score = 1e6
    best_point = nil
    @distance.each_index do |row|
      @distance[row].each_index do |col|
        if @distance[row][col] <= best_score && @unvisited.include?([row, col])
          best_score = @distance[row][col]
          best_point = [row, col]
        end
      end
    end
    best_point
  end

  def shortest_path
    current_node = @destination.clone
    until @unvisited.empty?
      # TODO: ask tomorrow whats going on with indices in the map
      cur_class = @map[current_node[1], @map.height - 1 - current_node[0]].class

      cur_score = @distance[current_node[0]][current_node[1]]

      if cur_class == Wall || cur_class == Rock || cur_class == Lift
        @unvisited.delete(current_node)
        current_node = best_unvisited
        next
      end

      [[-1,0], [1,0], [0,-1], [0,1]].each do |x,y|
        next_x = current_node[0] + x
        next_y = current_node[1] + y
        if next_x >=0 && next_y >= 0 && next_x <= @map.height - 1 && next_y <= @map.width - 1 && @unvisited.include?([next_x, next_y])
          next_class = @map[next_y, @map.height - 1 - next_x].class
          if next_class == Earth || next_class == Robot || next_class == Lambda || next_class == Empty || next_class == OpenLift
            score1 = cur_score + 1
            score2 = @distance[next_x][next_y]
            new_score = [score1, score2].min
            @distance[next_x][next_y] = new_score
          end
        end
      end
      @unvisited.delete(current_node)
      current_node = best_unvisited
    end
    @distance
  end
end

if __FILE__== $0
  map = Map.parse(STDIN.read)
  puts map.to_s
  # 0.upto(map.height-1).to_a.reverse.each {|x| p 0.upto(map.width - 1).map{|y| map[y,x].class }}
  x = ARGV.shift.to_i
  y = ARGV.shift.to_i
  d = Djikstra.new(map, [x,y])
  paths = d.shortest_path
  paths.reverse.each do |path|
    p path
  end
end
