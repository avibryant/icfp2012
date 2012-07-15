require '../fast/map'

map = FastMap.new(STDIN.read.split("\n"))
map.create_heatmap!
map2 = map
heatmap = []
map2.heatmap.each do |k, v|
  heatmap[k[1]] = [] if heatmap[k[1]] == nil
  heatmap[k[1]][k[0]] = v
end
puts heatmap.map {|r| r.join(",")}.join("\n")
puts map2.heatmap_value
puts map2.fixed_find('R').join(",")

puts map2.best_moves
puts map2.to_s
