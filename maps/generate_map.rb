#!/usr/bin/env ruby

### CONSTANTS ###

# Mapping from character types to relative frequency of occurance
# TODO: make more of these maps, and make their selection a runtime option
CELL_TYPES = {
  " "  => 10, # Blank
  "."  => 90, # Earth
  "*"  => 20, # Rock
  "\\" => 30, # Lambda
  "W"  => 2,  # Beard
  "!"  => 1,  # Razor,
  "#"  => 8
}

# Ranges for each scalar metadata value
METADATA_RANGES = {
  "Flooding" => (5..15),
  "Waterproof" => (5..20),
  "Growth" => (5..45),
  "Razors" => (5..15),
}

# Odds that each trampoline will have its own target
TARGET_RANDOMNESS = 0.2

### HELPERS ###

def compute_odds(cell_map)
  total = cell_map.values.inject(0) {|x,y| x+y }.to_f
  cell_map.map {|k,v| [v/total,k] }.sort_by {|p| p[0] }
end

def weighted_pick(distribution)
  win = rand
  pos = 0.0
  distribution.each do |odds, pick|
    pos += odds
    return pick if pos >= win
  end
end

def make_trampolines(count)
  trampolines = (0...count).map {|i| ("A".ord + i).chr }
  targets = []
  graph = {}
  trampolines.each do |t|
    target = (targets.last || "0").succ
    if targets.size > 0 && rand < TARGET_RANDOMNESS
      target = targets[rand(targets.size)]
    end
    graph[t] = target
    targets << target
  end
  graph
end

unless "".respond_to?(:ord)
class String
  def ord; self[0]; end
end
end

### SCRIPT CODE ###

width = ARGV.shift.to_i
height = ARGV.shift.to_i

unless width && height
  STDERR.puts "Usage: #{File.basename(__FILE__)} <width> <height>"
  exit 1
end

distribution = compute_odds(CELL_TYPES)

map = []
map << ["#"] * width
(height - 2).times do
  row = ["#"]
  (width - 2).times do
    row << weighted_pick(distribution)
  end
  row << "#"
  map << row
end
map << ["#"] * width

trampoline_count = rand(width / 5)
trampoline_count = 8 if trampoline_count > 8
trampolines = make_trampolines(trampoline_count)

trampolines.each do |src, dst|
  src_x = rand(width - 1)
  src_y = rand(height - 1)
  map[src_y][src_x] = src

  dst_x = rand(width - 1)
  dst_y = rand(height - 1)
  map[dst_y][dst_x] = dst
end

border_size = (width + height)*2 - 2
lift_side = rand(4)
if lift_side % 2 == 0
  lift_pos = rand(width)
  if lift_side == 0
    map[0][lift_pos] = "L"
  else
    map[height-1][lift_pos] = "L"
  end
else
  lift_pos = rand(height)
  if lift_side == 1
    map[lift_pos][0] = "L"
  else
    map[lift_pos][width-1] = "L"
  end
end

puts map.map {|row| row.join("") }.join("\n")
