package icfp2012.barbers

class TileState(state : IndexedSeq[IndexedSeq[Cell]]) {
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

  def colsRows : (Int,Int) = {
    val rows = state.size
    val cols = state.map { _.size }.max
    (cols, rows)
  }

  def allPositions : Seq[Position] = {
    val (cols, rows) = colsRows
    (0 until cols).flatMap { c =>
      (0 until rows).map { r => Position(c, r) }
    }
  }

  def positionMap(types : Set[Cell]) : Map[Cell, Seq[Position]] = {
    allPositions.filter { p => types(apply(p)) }
      .groupBy { apply }
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

object TileMap {

  def parseStdin : TileMap = parse(io.Source.stdin.getLines)

  def parse(string : String) : TileMap = parse(string.split("\n"))

  def parse(lines : TraversableOnce[String]) : TileMap = {
    // Make the tileState:
    val ts = new TileState(lines
      .toIndexedSeq
      .map { line : String =>
        line.toIndexedSeq.map { c : Char => Cell.parse(c) }
      }
      // We read from bottom to top, so we must reverse
      .reverse)
    // Look for the robot, rocks, lambdas and closed lift:
    val pmap = ts.positionMap(Set(Robot, Rock, Lambda, CLift))
    // We have enough to build the tileMap:
    new TileMap(ts, RobotState(Nil, List(pmap(Robot).head)),
      pmap(Rock).toSet, Nil, pmap(Lambda).toSet, pmap(CLift)(0), false)
  }

}

/*
 * Immutable class representing the update/scoring rules of the 2012 contest
 */
case class TileMap(state : TileState, robotState : RobotState,
  rocks : Set[Position], collectedLam : List[Position],
  remainingLam : Set[Position], liftPos : Position, completed : Boolean) {

  override def toString = state.toString

  def move(mv : Move) : TileMap = moveRobot(mv).moveRocks

  protected def moveRocks : TileMap = {
    if (completed) return this

    // These are the writes we need to do:
    val emptyAndRocks = List[(Position,Position)]()
    val writes = rocks.toList.sorted.foldLeft(emptyAndRocks) { (eAr, pos) =>
      val down = pos.move(Down)
      val right = pos.move(Right)
      val rightDown = right.move(Down)
      val left = pos.move(Left)
      val leftDown = left.move(Down)

      val below = state(down)

      if(below == Empty) {
        //Fall down
        (pos, down) :: eAr
      }
      else if((below == Rock || below == Lambda) &&
          (state(right) == Empty) &&
          (state(rightDown) == Empty)) {
        //Fall right
        (pos, rightDown) :: eAr
      }
      else if(below == Rock &&
          (state(left) == Empty) &&
          (state(leftDown) == Empty)) {
        //Fall left
        (pos, leftDown) :: eAr
      }
      else {
        // No movement at all
        eAr
      }
    }
    // Remove the erased:
    val newRocks = writes.foldLeft(rocks) { (r, er) => (r - er._1) + er._2}
    // Update the state:
    val newState = writes.foldLeft(state) { (s, er) =>
      state
        .updated(er._1, Empty)
        .updated(er._2, Rock)
    }
    copy(state = newState, rocks = newRocks)
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


