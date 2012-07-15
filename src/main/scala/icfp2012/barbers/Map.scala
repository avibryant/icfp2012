package icfp2012.barbers

class TileState(state : Vector[Vector[Cell]]) {
  def apply(p : Position) : Cell = {
    if (p.y < state.size && p.y >= 0) {
      val row = state(p.y)
      if (p.x < row.size && p.x >= 0)
        row(p.x)
      else
        Empty
    }
    else {
      Empty
    }
  }
  def updated(p : Position, c : Cell) : TileState = {
    val row = state(p.y)
    val newRow = row.updated(p.x, c)
    new TileState(state.updated(p.y, newRow))
  }

  override lazy val toString : String = {
    //Reverse the rows, so they start at the largest number:
    state.reverse
       // Here is each row:
      .map { _.map { Cell.charOf(_) }.mkString("") }
      // Join them all together
      .mkString("\n")
  }
}

case class RockList(rocks : List[Position]) {
  def ::(pos : Position) = RockList(pos :: rocks)
  def move(old : Position, newP : Position) : RockList = {
    RockList(rocks.indexOf(old) match {
      case -1 => error(old.toString + " not a rock")
      case idx => rocks.updated(idx, newP)
    })
  }
}

/*
 * Immutable class representing the update/scoring rules of the 2012 contest
 */
class TileMap(state : TileState, robotState : RobotState,
  rocks : RockList, lambdas : List[Position], completed : Boolean) {

  override def toString = state.toString

  def move(mv : Move) : TileMap = moveRobot(mv).moveRocks

  protected def moveRocks : TileMap = {
    this
  }

  protected def moveRobot(mv : Move) : TileMap = {
    if (completed) return this

    val newRobotState = robotState.move(mv)
    val newPos = newRobotState.pos
    val newCell = state(newPos)

    lazy val emptiedTileState = state
      .updated(robotState.pos, Empty)
      .updated(newPos, Robot)

    newCell match {
      case Empty => {
        new TileMap(emptiedTileState, newRobotState, rocks, lambdas, false)
      }
      case Earth => {
        new TileMap(emptiedTileState, newRobotState, rocks, lambdas, false)
      }
      case Lambda => {
        // Picked up a new Lambda:
        new TileMap(emptiedTileState, newRobotState, rocks,
          newPos :: lambdas, false)
      }
      case OLift => {
        new TileMap(emptiedTileState, newRobotState, rocks, lambdas, true)
      }
      case Rock => {
        // We can push rocks left/right
        mv match {
          case Right => state(newPos.move(Right)) match {
            case Empty => {
              // Move the rock right:
              val newRockPos = newPos.move(Right)
              val movedTileState = emptiedTileState.updated(newRockPos, Rock)
              //Move the rocks
              new TileMap(movedTileState, newRobotState,
                rocks.move(newPos, newRockPos), lambdas, false)
            }
            case _ => this
          }
          case Left => state(newPos.move(Left)) match {
            case Empty => {
              // Move the rock right:
              val newRockPos = newPos.move(Left)
              val movedTileState = emptiedTileState.updated(newRockPos, Rock)
              //Move the rocks
              new TileMap(movedTileState, newRobotState,
                rocks.move(newPos, newRockPos), lambdas, false)
            }
            case _ => this
          }
          case _ => this
        }
      }
      case _ => this
    }
  }

  def score : Int = -1
}


