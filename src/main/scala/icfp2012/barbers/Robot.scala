package icfp2012.barbers

case class Position(x : Int, y: Int) extends Ordered[Position] {
  def move(m : Move) : Position = m match {
    case Left => Position(x-1, y)
    case Right => Position(x+1, y)
    case Up => Position(x, y+1)
    case Down => Position(x, y-1)
    case _ => this
  }

  def neighbors4 : List[Position] = {
    List(move(Up), move(Right), move(Up), move(Down))
  }

  def neighbors8 : List[Position] = {
    neighbors4 ++ List(
      Position(x+1, y+1),
      Position(x-1, y-1),
      Position(x+1, y-1),
      Position(x-1, y+1)
    )
  }

  override def compare(other : Position) : Int = {
    // Left to right, the bottom to top, so, y, then x:
    y.compareTo(other.y) match {
      case 0 => x.compareTo(other.x)
      case c => c
    }
  }
}

case class RobotState(moves : List[Move], history : List[Position]) {
  // for trampolines:
  def jump(mv : Move, p : Position) = RobotState(mv :: moves, p :: history)
  def pos = history.head
  def move(mv : Move) = jump(mv, pos.move(mv))
  // Record the move, but don't actually move the bot (jump in place)
  def invalidMove(mv : Move) = jump(mv, pos)
  def isAborted : Boolean = moves.headOption.map { _ == Abort }.getOrElse(false)
  def beardNeighbors(beards : Set[Position]) = pos.neighbors8.filter{ n => beards.contains(n) }.toSet
}

object Move {
  def charOf(m : Move) = m match {
    case Left => 'L'
    case Right => 'R'
    case Up => 'U'
    case Down => 'D'
    case Wait => 'W'
    case Abort => 'A'
    case Shave => 'S'
  }
  val parser = Map('L' -> Left,
    'R' -> Right,
    'U' -> Up,
    'D' -> Down,
    'W' -> Wait,
    'A' -> Abort,
    'S' -> Shave)

  def parse(c : Char) : Move = parser(c)
}

sealed abstract class Move
case object Left extends Move
case object Right extends Move
case object Up extends Move
case object Down extends Move
case object Wait extends Move
case object Abort extends Move
case object Shave extends Move
