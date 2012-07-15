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
      Position(x-y, y+1)
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
  def pos = history.head
  def move(mv : Move) = {
    val newPos = pos.move(mv)
    RobotState(mv :: moves, newPos :: history)
  }
  // Record the move, but don't actually move the bot
  def invalidMove(mv : Move) = {
    RobotState(mv :: moves, pos :: history)
  }
  def isAborted : Boolean = moves.headOption.map { _ == Abort }.getOrElse(false)
}

object Move {
  def charOf(m : Move) = m match {
    case Left => 'L'
    case Right => 'R'
    case Up => 'U'
    case Down => 'D'
    case Wait => 'W'
    case Abort => 'A'
  }
  val parser = Map('L' -> Left,
    'R' -> Right,
    'U' -> Up,
    'D' -> Down,
    'W' -> Wait,
    'A' -> Abort)

  def parse(c : Char) : Move = parser(c)
}

sealed abstract class Move
case object Left extends Move
case object Right extends Move
case object Up extends Move
case object Down extends Move
case object Wait extends Move
case object Abort extends Move
