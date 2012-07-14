require 'set'
require 'map'

class Djikstra
  attr_accessor :distance, :map

  def initialize(map, dest)
    @map = map.clone
    @destination = dest.clone
    @unvisited = Set.new

    @distance = (0...map.height).map do |y|
      (0...map.width).map do |x|
        @unvisited << [x, y]
        1e6
      end
    end

    @unvisited.delete(dest)
    @distance[dest[1]][dest[0]] = 0
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
      break if current_node.nil?
      cur_class = @map.cells[current_node[0]][current_node[1]].class
      cur_score = @distance[current_node[0]][current_node[1]]
      if cur_class == Wall || cur_class == Rock || cur_class == Lift
        @unvisited.delete(current_node)
        current_node = best_unvisited
        next
      end

      [[-1,0], [1,0], [0,-1], [0,1]].each do |y,x|
        next_x = current_node[0] + x
        next_y = current_node[1] + y
        if next_x >=0 && next_y >= 0 && next_x < @map.height && next_y < @map.width && @unvisited.include?([next_x, next_y])
          next_class = @map.cells[next_x][next_y].class
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
      break if current_node.nil?
    end
    @distance
  end
end

if __FILE__== $0
  map = Map.parse(STDIN.read)
  map.score_cells!
  puts map.to_s
  x = ARGV.shift.to_i
  y = ARGV.shift.to_i
  puts map[x, y]
  d = Djikstra.new(map, [x,y])
  paths = d.shortest_path
  paths.reverse.each do |path|
    p path
  end
end
