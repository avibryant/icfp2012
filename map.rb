class LambdaMap
  mapString = <<-STR
######
#. *R#
#  \\.#
#\\ * #
L  .\\#
######
STR

  def printMap
    puts @map.reverse
  end

  def populateMap
    @map = mapString.split("\n").reverse
  end

  def get(x,y)
    @map[y][x] || ' '
  end

end

class Robot

end

class Rock

end
