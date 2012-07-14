require 'map'

class BaseAlg
  #MOVES = ["L", "R", "U", "D", "A", "W"]
  MOVES = ["L", "R", "U", "D", "A", "W"]
  def rand_move
    MOVES[rand(MOVES.size)]
  end

  def rand_move_with_empty
    pos = rand(MOVES.size + 1)
    if pos == MOVES.size
      ""
    else
      MOVES[pos]
    end
  end
end

class BlindWatchMaker < BaseAlg
  attr_reader :map, :empty_map

  def initialize(empty_map, map)
    @empty_map = empty_map
    @map = map
  end

  def mutate
    pos = rand(map.moves.size + 1)
    if pos == map.moves.size
      #append:
      BlindWatchMaker.new(empty_map, map.move(rand_move))
    else
      #replace:
      moves = String.new(map.moves)
      moves[pos] = rand_move_with_empty
      BlindWatchMaker.new(empty_map, move_seq_to_map(moves))
    end
  end

  def move_seq_to_map(moves)
    moves.split("").inject(empty_map) { |mp,mv| mp.move(mv) }
  end

  def cross_with(other)
    cross_over_pos = rand([map.moves.size, other.map.moves.size].min)
    if cross_over_pos < 1
      #this means 
      self
    end

    if 0 == rand(2)
      nm = other.map.moves[0...cross_over_pos] + map.moves[cross_over_pos...map.moves.size]
    else
      nm = map.moves[0...cross_over_pos] + other.map.moves[cross_over_pos...other.map.moves.size]
    end
    BlindWatchMaker.new(empty_map, move_seq_to_map(nm))
  end

  def self.top_pairs(scored, max)
    scored.sort!{|a,b| b[0] <=> a[0]}
    top = scored.take(Math.sqrt(max) + 1)
    top.map { |e1| top.map { |e2| [e1,e2] } }.flatten(1)
  end

  # TODO: this is super slow, build a sumscore => idx, do a binary search
  def self.select_propto_score(scored_individuals, minscore, sumdeltamin)
    if sumdeltamin == 0
      #random
      scored_individuals[ rand(scored_individuals.size) ]
    end
    select_v = rand(0) * sumdeltamin
    scored_individuals.inject(0) { |score, se|
      if score > select_v
        return se
      end
      score + (se[0] - minscore)
    }
    scored_individuals[-1]
  end

  def self.proportional_to_score_pairs(scored, max)
    if scored.size == 1
      scored[0]
    end
    minscore = scored.map { |e| e[0] }.min
    sumdeltamin = scored.map { |e| (e[0] - minscore) }.inject(0) { |x,y| x+y }
    #sort by score so we don't have to go too deep:
    scored.sort! { |e1,e2| e2[0] <=> e1[0] }
    #no need to over-select a small population
    max = [scored.size, max].max
    (0...max).map {
      x = select_propto_score(scored, minscore, sumdeltamin)
      y = select_propto_score(scored, minscore, sumdeltamin)
      [x,y]
    }
  end

  def self.next_generation(examples, max, mutants = 1)
    mutants = examples.map { |e| (0...mutants).map { e.mutate } }.flatten
    individuals = (mutants + examples)
    scored = individuals.map { |e| [e.map.score, e] }
    tocross = self.top_pairs(scored,max)
    #tocross = self.proportional_to_score_pairs(scored,max)
    crossed = tocross.map { |e| (e[0][1]).cross_with(e[1][1]) }
    #crossed = []
    #make sure to keep the top individuals
    all_moves = {}
    (crossed + individuals).each { |elem|
      all_moves[elem.map.moves] = elem
    }
    all = all_moves.values
    all.sort! { |e1,e2| e2.map.score <=> e1.map.score }
    all.take(max)
  end

  def to_s
    "-- score: " + map.score.to_s + "\n" + "moves: " + map.moves.to_s + "\n"
  end

  def ==(other)
    map.moves == other.map.moves
  end
end

# For small maps, 1000 population ~ 20 generations works
# ruby genetic.rb 1000 20 < ../../maps/contest2/base

map = FastMap.new(STDIN.read.split("\n"))
generation = [BlindWatchMaker.new(map, map)]
gen_size = ARGV.shift.to_i
max_time = ARGV.shift.to_i

max_time.times {
  generation = BlindWatchMaker.next_generation(generation, gen_size, 6)
  #print average score:
  s_max = generation.max { |e1,e2| e1.map.score <=> e2.map.score }
  puts "max score: ", s_max.map.score
  #puts "map: ", s_max.map
  puts "moves:", s_max.map.moves
}
