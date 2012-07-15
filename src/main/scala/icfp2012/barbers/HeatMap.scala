package icfp2012.barbers

object HeatMap {
  val NEG_INF = -10000
}

/**
 * WARNING: here be mutation
 */
class HeatMap(map: TileMap){
  import HeatMap.NEG_INF

  def apply(pos : Position) = heatCellAt(pos).value

  def heatCellAt(pos : Position) = state(pos.y)(pos.x)
  def setCell(hmc : HeatMapCell) {
    val newRow = state(hmc.pos.y).updated(hmc.pos.x, hmc)
    state = state.updated(hmc.pos.y, newRow)
  }

  var state : IndexedSeq[IndexedSeq[HeatMapCell]] = map.state.cells.zipWithIndex.map {
    rowy =>
    val (row, y) = rowy
    row.zipWithIndex.map {
      cellx =>
      val (cell, x) = cellx
      new HeatMapCell(cell, heatOf(cell), Position(x,y))
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
      case Beard => NEG_INF
      case Razor => 0
      case Trampoline(c) => NEG_INF //TODO probably should be smarter
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


    val changed = requiresUpdate
      .foldLeft(Set[(HeatMapCell, Set[HeatMapCell])]()) { (changed, cell) =>
        val validNeighbors = List(Down,Left,Up,Right)
          .map { cell.pos.move(_) }
          .filter{position =>
            // Ignore positions out of the space:
            position.y >= 0 &&
            position.x >= 0 &&
            position.y < state.size &&
            position.x < state(position.y).size
          }
          .map{ heatCellAt(_) }

        val newCell = cell.update(validNeighbors)
        if (cell.value != newCell.value) {
          changed + ((newCell, validNeighbors.toSet))
        }
        else {
          changed
        }
    }
    // Now mutate:
    changed.foreach { change => setCell(change._1) }

    val changedNeighbors = changed.flatMap{ _._2 }.toSet

    furtherPopulate(changedNeighbors, iterations + 1)
  }
}

class HeatMapCell(val cell : Cell, val value : Int, val pos : Position){
  import HeatMap.NEG_INF

  override lazy val toString : String = {
    if(value <= NEG_INF) " . " else "%3d".format(value)
  }
  def update(neighbors : List[HeatMapCell]) : HeatMapCell = {
    if (cell == Wall)
      //walls never change:
      if( value == NEG_INF) {
        this
      }
      else {
        // Can't see how this would actually happen TODO: remove
        new HeatMapCell(cell, NEG_INF, pos)
      }
    else if (cell == Rock)
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 5}).max, pos)
    else
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 1}).max, pos)
  }
}
