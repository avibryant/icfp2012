tests = {}

STDIN.read.each do |line|
  values = line.split("\t")
  tests[values[0]] = {"speed" => [], "score" => []} if tests[values[0]] == nil
  tests[values[0]]["speed"] << values[1].to_f
  tests[values[0]]["score"] << values[3].to_f
end
tests.each do |key, value|
  total_time = value["speed"].inject(:+)
  total_score = value["score"].inject(:+)
  average_time = total_time / value["speed"].size
  average_score = total_score / value["score"].size
  puts "#{key} ran #{value["score"].size} time"
  puts "#{key} average_time: #{average_time}"
  puts "#{key} average_score: #{average_score}"
end
