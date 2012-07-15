package icfp2012.barbers

class HeatMap(map: TileMap){
  var cells = map.state.cells

  def apply(pos : Position) = {
    state(pos.y)(pos.x).value
  }

  var state = cells.zipWithIndex.map {
    rowy =>
    val (row, y) = rowy
    row.zipWithIndex.map {
      cellx =>
      val (cell, x) = cellx 
      new HeatMapCell(cell, Cell.heatOf(cell), (x,y))
    }
  }

  override def toString : String = {
    state.reverse
      .map { _.mkString(" ")}
      .mkString("\n")
  }

  def populate = {
    furtherPopulate(state.flatten.toSet, 0)
  }

  def furtherPopulate(requiresUpdate : Set[HeatMapCell], iterations : Int) : Boolean = {
    if ((iterations > 20) || (requiresUpdate.size == 0)) 
      return requiresUpdate.size == 0

    var changed : Set[(HeatMapCell, (Int,Int), Set[HeatMapCell])] = Set.empty
    requiresUpdate.foreach{
        cell =>
        val x = cell.x
        val y = cell.y
        val neighborPositions : Set[(Int,Int)] = Set((x, y - 1), (x - 1, y), (x, y + 1), (x + 1, y))
        val validNeighbors = neighborPositions
          .filter{position : (Int, Int) => 
            position._2 >= 0 && position._2 < state.size && position._1 >= 0 && position._1 < state(position._2).size
          }
          .map{ position => state(position._2)(position._1)}
        val newCell = cell.update(validNeighbors)
        if (cell.value != newCell.value) changed = changed ++ Set((newCell, (x,y), validNeighbors))
    }
    changed.foreach {
      change => 
      val newRow = state(change._2._2).updated(change._2._1, change._1)
      state = state.updated(change._2._2, newRow)
    }
    val changedNeighbors = changed.map{change => change._3}.flatten.toSet

    furtherPopulate(changedNeighbors, iterations + 1)
  }
}

class HeatMapCell(cell : Cell, initialValue : Int, position : (Int, Int)){
  val value : Int = {initialValue}
  override lazy val toString : String = {
    if(value <= -10000) " . " else "%3d".format(value)
  }
  val x = {position._1}
  val y = {position._2}
  def update(neighbors : Set[HeatMapCell]) : HeatMapCell = {
    if (cell == Wall) new HeatMapCell(cell, -10000, position) else new HeatMapCell(cell, (Set(value) ++ neighbors.map{n => n.value - 1}).max, position)
  }
}
