package icfp2012.barbers

import scala.annotation.tailrec

object HeatMap {
  val NEG_INF = -10000

  def init(map : TileMap) : HeatMap = {
    val state : IndexedSeq[IndexedSeq[HeatMapCell]] = map.state.cells.zipWithIndex.map {
      rowy =>
      val (row, y) = rowy
      row.zipWithIndex.map {
        cellx =>
        val (cell, x) = cellx
        // TODO: the second position is unused now
        new HeatMapCell(cell, initHeatOf(map, cell), Position(x,y), Position(x,y))
      }
    }
    new HeatMap(map, state)
  }

  def initHeatOf(tm : TileMap, c : Cell) : Int = {
    c match {
      case Robot => NEG_INF
      case Rock => NEG_INF
      case CLift => NEG_INF
      case Earth => NEG_INF
      case Wall => NEG_INF
      case Lambda => 25
      case OLift => (tm.totalLambdas * 25)
      case Empty => NEG_INF
      case Beard => NEG_INF
      case Razor => 0
      case Trampoline(c) => NEG_INF //TODO probably should be smarter
      case Target(_) => NEG_INF //Same as a wall
    }
  }


  @tailrec
  def populate(hm : HeatMap, requiresUpdate : Set[HeatMapCell] = null, iterations : Int = 0) : HeatMap = {
    if(requiresUpdate == null) {
      //initial case:
      populate(hm, hm.heatState.flatten.toSet, 0)
    }
    else if ((iterations > 20) || (requiresUpdate.size == 0))
      hm
    else {
      val changed = requiresUpdate
        .foldLeft(Set[(HeatMapCell, Set[HeatMapCell])]()) { (changed, cell) =>
          val validNeighbors = List(Down,Left,Up,Right)
            .map { cell.pos.move(_) }
            .filter{ hm.consider(_) }
            .map{ hm.heatCellAt(_) }

          val newCell = cell.update(validNeighbors)
          if (cell.value != newCell.value) {
            changed + ((newCell, validNeighbors.toSet))
          }
          else {
            changed
          }
      }
      val newHm = changed.foldLeft(hm) { (oldState, change) => oldState.setCell(change._1) }
      val changedNeighbors = changed.flatMap{ _._2 }.toSet

      populate(newHm, changedNeighbors, iterations + 1)
    }
  }
}

class HeatMap(val tileMap: TileMap, val heatState : IndexedSeq[IndexedSeq[HeatMapCell]]) {
  import HeatMap.NEG_INF

  def apply(pos : Position) = heatCellAt(pos).value

  def heatCellAt(pos : Position) = heatState(pos.y)(pos.x)
  def setCell(hmc : HeatMapCell) : HeatMap = {
    val newRow = heatState(hmc.pos.y).updated(hmc.pos.x, hmc)
    val newState = heatState.updated(hmc.pos.y, newRow)
    new HeatMap(tileMap, newState)
  }

  override def toString : String = {
    heatState.reverse
      .map { _.mkString(" ")}
      .mkString("\n")
  }

  def consider(position : Position) : Boolean =
    position.y >= 0 &&
    position.x >= 0 &&
    position.y < heatState.size &&
    position.x < heatState(position.y).size

}

class HeatMapCell(val cell : Cell, val value : Int, val pos : Position, val targetPos : Position){
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
        new HeatMapCell(cell, NEG_INF, pos, targetPos)
      }
    else if (cell == Rock)
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 10}).max, pos, targetPos)
    else
      new HeatMapCell(cell, (value :: neighbors.map{n => n.value - 1}).max, pos, targetPos)
  }
}
