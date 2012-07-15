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

/*
 * Immutable class representing the update/scoring rules of the 2012 contest
 */
case class TileMap(state : TileState, robotState : RobotState,
  rocks : Set[Position], collectedLam : List[Position],
  remainingLam : Set[Position], completed : Boolean) {

  override def toString = state.toString

  def move(mv : Move) : TileMap = moveRobot(mv).moveRocks

  protected def moveRocks : TileMap = {
    if (completed) return this
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
        copy(state = emptiedTileState, robotState = newRobotState)
      }
      case Earth => {
        copy(state = emptiedTileState, robotState = newRobotState)
      }
      case Lambda => {
        // Picked up a new Lambda:
        copy(state = emptiedTileState,
          robotState = newRobotState,
          collectedLam = newPos :: collectedLam,
          remainingLam = remainingLam - newPos
          )
      }
      case OLift => {
        copy(state = emptiedTileState,
          robotState = newRobotState,
          completed = true)
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
              copy(state = emptiedTileState,
                robotState = newRobotState,
                rocks = (rocks - newPos) + newRockPos)
            }
            case _ => this
          }
          case Left => state(newPos.move(Left)) match {
            case Empty => {
              // Move the rock to the left:
              val newRockPos = newPos.move(Left)
              val movedTileState = emptiedTileState.updated(newRockPos, Rock)
              //Move the rocks
              copy(state = emptiedTileState,
                robotState = newRobotState,
                rocks = (rocks - newPos) + newRockPos)
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


