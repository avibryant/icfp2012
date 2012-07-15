package icfp2012.barbers

/**
 * Immutable object strictly representing the cell-map, no rules for movement
 * or scoring
 */
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

  def cells = {state}

  def contains(p : Position) : Boolean = {
    val nonNeg = p.x >= 0 && p.y >= 0
    if(nonNeg) {
      val (cols, rows) = colsRows
      p.x < cols && p.y < rows
    }
    else {
      false
    }
  }

  lazy val colsRows : (Int,Int) = {
    val rows = state.size
    val cols = state.map { _.size }.max
    (cols, rows)
  }

  protected def allPositions : Seq[Position] = {
    val (cols, rows) = colsRows
    (0 until cols).flatMap { c =>
      (0 until rows).map { r => Position(c, r) }
    }
  }

  // Where are the given cell types to be found?
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
    val linesSeq = lines.toIndexedSeq
    var metadataIndex = linesSeq.indexOf("")
    if(metadataIndex < 0)
      metadataIndex = linesSeq.size

    val ts = new TileState(linesSeq
        .take(metadataIndex)
        .map { line : String =>
        line.toIndexedSeq.map { c : Char => Cell.parse(c) }
      }
      // We read from bottom to top, so we must reverse
      .reverse)
    // Look for the robot, rocks, lambdas and closed lift:
    val targetSet = Cell.targets.values.toSet
    val trampSet = Cell.trampolines.values.toSet
    val pmap = ts.positionMap(Set(Robot, Rock, Lambda, CLift, Beard, Razor) ++ targetSet ++ trampSet)

    val metadataTokens = linesSeq.drop(metadataIndex+1).map {line =>
      val parts = line.split(" ")
      (parts.head, parts.tail.toList)
    }
    // These are the ones we don't track in cellPositions:
    val untrackedKeys = Set(Robot)
    val cellPositions : Map[Cell, Set[Position]] = (pmap -- untrackedKeys).mapValues { _.toSet }

    //Todo: extension-specific parsing of metadataTokens goes here
    val water = WaterState.parse(metadataTokens)
    val tramps = TrampolineState.parse(metadataTokens)
    val beardGrowth = TextHelper.parseInt(metadataTokens, "Growth", 0)
    val razorCount = TextHelper.parseInt(metadataTokens, "Razors", 0)

    // We have enough to build the tileMap:
    new TileMap(ts, RobotState(Nil, List(pmap(Robot).head)),
      cellPositions, Nil, false, false, water, tramps, beardGrowth, razorCount)
  }

}

abstract class GameState
case object Playing extends GameState
case object Winning extends GameState
case object Losing extends GameState
case object Aborted extends GameState

/*
 * Immutable class representing the update/scoring rules of the 2012 contest
 */
case class TileMap(state : TileState, robotState : RobotState,
  cellPositions: Map[Cell, Set[Position]], collectedLam : List[Position],
  completed : Boolean, botIsCrushed : Boolean, waterState : WaterState,
  trampState : TrampolineState, beardGrowthRate : Int, razorCount : Int) {

  override lazy val toString = {
    "map: \n" + state.toString + "\n" +
    "score: " + score.toString + "\n" +
    "move count: " + robotState.moves.size + "\n" +
    "moves: " + robotState.moves.reverse.map { Move.charOf(_) }.mkString("") + "\n" +
    "heatmap: \n" + heatmap + "\n" +
    waterState.toString + "\n"
  }

  lazy val numberOfMoves = robotState.moves.size
  lazy val heatmap = new HeatMap(this).populate

  def move(mv : Move) : TileMap = moveRobot(mv).growBeards.moveRocks

  lazy val rocks : Set[Position] = cellPositions(Rock)
  lazy val remainingLam : Set[Position] = cellPositions(Lambda)
  lazy val liftPos : Position = cellPositions(CLift).head
  lazy val beardPos : Set[Position] = cellPositions.getOrElse(Beard, Set[Position]())
  lazy val razorPos : Set[Position] = cellPositions.getOrElse(Razor, Set[Position]())

  protected def growBeards : TileMap = {
    if (beardPos.isEmpty || numberOfMoves % beardGrowthRate != 0) {
      return this
    }

    val (cols, rows) = state.colsRows

    var newBeards = beardPos ++ beardPos.flatMap { pos =>
      pos.neighbors8.filter { n =>
        n.x >= 0 && n.x < cols && n.y >= 0 && n.y < rows && state(n) == Empty
      }
    }

    var newState = newBeards.foldLeft(state) { (s, pos) => s.updated(pos, Beard) }
    var newCellPositions = cellPositions + (Beard -> newBeards)
    copy(state = newState, cellPositions = newCellPositions)
  }

  protected def moveRocks : TileMap = {
    if (gameState != Playing) {
      return this
    }

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
    val dangerZone = robotState.pos.move(Up)
    // Make sure none of the new positions are in the dangerZone
    val newBotIsCrushed = writes.forall { _._2 != dangerZone } == false
    val newCellPositions = cellPositions + (Rock -> newRocks)
    val newWaterState = waterState.update(robotState)

    copy(state = newState, cellPositions = newCellPositions,
      botIsCrushed = newBotIsCrushed, waterState = newWaterState)
  }

  lazy val gameState : GameState = {
    // If we have a rock above us, we are toast
    if( completed ) {
      Winning
    }
    else if (botIsCrushed || waterState.botIsDrowned) {
      Losing
    }
    else if (robotState.isAborted) {
      Aborted
    }
    else {
      Playing
    }
  }

  protected def moveRobot(mv : Move) : TileMap = {
    if (gameState != Playing) {
      return this
    }

    val newRobotState = robotState.move(mv)
    val newPos = newRobotState.pos
    val newCell = state(newPos)

    lazy val emptiedTileState = state
      .updated(robotState.pos, Empty)
      .updated(newPos, Robot)

    lazy val invalidNext = {
      copy(robotState = robotState.invalidMove(mv))
    }

    newCell match {
      case Empty | Earth => {
        copy(state = emptiedTileState, robotState = newRobotState)
      }
      case Lambda => {
        // Picked up a new Lambda:
        val newRLam = remainingLam - newPos
        val newState = if(newRLam.size == 0) {
          //Open the lift:
          emptiedTileState.updated(liftPos, OLift)
        }
        else {
          emptiedTileState
        }
        val newCellPositions = cellPositions + (Lambda -> newRLam)

        copy(state = newState,
          robotState = newRobotState,
          collectedLam = newPos :: collectedLam,
          cellPositions = newCellPositions)
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
              val newRocks = (rocks - newPos) + newRockPos
              val newCellPositions = cellPositions + (Rock -> newRocks)
              //Move the rocks
              copy(state = movedTileState,
                robotState = newRobotState,
                cellPositions = newCellPositions)
            }
            case _ => invalidNext
          }
          case Left => state(newPos.move(Left)) match {
            case Empty => {
              // Move the rock to the left:
              val newRockPos = newPos.move(Left)
              val movedTileState = emptiedTileState.updated(newRockPos, Rock)
              val newRocks = (rocks - newPos) + newRockPos
              val newCellPositions = cellPositions + (Rock -> newRocks)
              //Move the rocks
              copy(state = movedTileState,
                robotState = newRobotState,
                cellPositions = newCellPositions)
            }
            case _ => invalidNext
          }
          case _ => invalidNext
        }
      }
      case Razor => {
        val newRazors = razorPos - newPos
        val newCellPositions = cellPositions + (Razor -> newRazors)
        val newState = state.updated(newPos, Empty)
        copy(state = newState, cellPositions = newCellPositions, razorCount = razorCount + 1)
      }
      case Target(_) => invalidNext //Targets are walls until used
      case tramp@Trampoline(_) => {
        // Move immediately to the target of this trampoline:
        val target = trampState.targetFor(tramp)
        val jumpPos = cellPositions(target).head // there should be only one target
        val (invalidTramps, newTrampState) = trampState.jumpOn(tramp)
        // Invalidate the trampolines
        val newState = invalidTramps.foldLeft(state) { (oldstate, tramp) =>
            oldstate.updated(cellPositions(tramp).head, Empty)
          }
          // Move the robot:
          .updated(robotState.pos, Empty)
          .updated(jumpPos, Robot)
        // Remove the target and invalidated tramps
        val newCellPositions = (cellPositions - target) -- invalidTramps
        val newRobotState = robotState.jump(mv, jumpPos)
        copy(state = newState, robotState = newRobotState,
          trampState = newTrampState, cellPositions = newCellPositions)
      }
      case _ => invalidNext
    }
  }

  lazy val score : Int = {
    val (multiplier, offset) = gameState match {
      case Winning => (3, 0)
      case Aborted => (2, 1)
      case _ => (1, 0)
    }

    collectedLam.size * 25 * multiplier -
      robotState.moves.size +
      offset
  }

  lazy val abortScore : Int = {
    if(gameState == Playing)
      move(Abort).score
    else
      score
  }

  lazy val heatmapScore = heatmap(robotState.pos)

  def progressScore = {
    if(completed)
        score
      else
        //todo these may want different weights
        (abortScore.toDouble / 3) + (heatmapScore)
  }

  def scoreRatio = score.toDouble / (totalLambdas * 75)

  lazy val totalLambdas = collectedLam.size + remainingLam.size
  lazy val progress = progressScore.toDouble / (totalLambdas * 75)

  lazy val validMoves = {
    if(completed)
      List(Wait)
    else {
      List(Left, Down, Right, Up).map{dir => (dir, heatmap(robotState.pos.move(dir)))}
        .sortBy(_._2)
        .map(_._1)
        .reverse ++
      List(Wait)
    }
  }

  def moveScores = {
    List(Left, Down, Right, Up).map{dir => (dir, move(dir).heatmapScore, move(dir).progressScore)}
  }
}


