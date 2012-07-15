package icfp2012.barbers

object HeatMap {
  val NEG_INF = -10000
}

class HeatMap(map: TileMap){
  import HeatMap.NEG_INF

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
      new HeatMapCell(cell, heatOf(cell), (x,y))
    }
  }

  def heatOf(c : Cell) : Int = {
    c match {
      case Robot => NEG_INF
      case Rock => NEG_INF
      case CLift => NEG_INF
      case Earth => NEG_INF
      case Wall => NEG_INF
      case Lambda => 25
      case OLift => (map.totalLambdas * 25)
      case Empty => NEG_INF
      case Trampoline(c) => 0 //TODO probably should be smarter
      case Target(_) => NEG_INF //Same as a wall
    }
  }

  override def toString : String = {
    state.reverse
      .map { _.mkString(" ")}
      .mkString("\n")
  }

  def populate = {
    furtherPopulate(state.flatten.toSet, 0)
    this
  }

  def furtherPopulate(requiresUpdate : Set[HeatMapCell], iterations : Int) : Boolean = {
    if ((iterations > 20) || (requiresUpdate.size == 0))
      return requiresUpdate.size == 0

    var changed : Set[(HeatMapCell, (Int,Int), Set[HeatMapCell])] = Set.empty
    requiresUpdate.foreach{
        cell =>
        val x = cell.x
        val y = cell.y
        val nX = cell.nX
        val nY = cell.nY

        val neighborPositions = List((nX, nY - 1), (nX - 1, nY), (nX, nY + 1), (nX + 1, nY))
        val validNeighbors = neighborPositions
          .filter{position : (Int, Int) =>
            position._2 >= 0 && position._2 < state.size && position._1 >= 0 && position._1 < state(position._2).size
          }
          .map{ position => state(position._2)(position._1)}
        val newCell = cell.update(validNeighbors)
        if (cell.value != newCell.value) changed = changed ++ Set((newCell, (x,y), validNeighbors.toSet))
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
  import HeatMap.NEG_INF
  val value : Int = {initialValue}
  override lazy val toString : String = {
    if(value <= NEG_INF) " . " else "%3d".format(value)
  }
  val x = {position._1}
  val y = {position._2}
  val nX = {x}
  val nY = {y}

  def update(neighbors : List[HeatMapCell]) : HeatMapCell = {
    if (cell == Wall)
      //walls never change:
      if( initialValue == NEG_INF) {
        this
      }
      else {
        // Can't see how this would actually happen TODO: remove
        new HeatMapCell(cell, NEG_INF, position)
      }
    else if (cell == Rock)
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 5}).max, position)
    else
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 1}).max, position)
  }
}
