package icfp2012.barbers

case class Position(x : Int, y: Int) {
  def move(m : Move) : Position = m match {
    case Left => Position(x-1, y)
    case Right => Position(x+1, y)
    case Up => Position(x, y+1)
    case Down => Position(x, y-1)
    case _ => this
  }
}

case class RobotState(moves : List[Move], history : List[Position]) {
  def pos = history.head
  def move(mv : Move) = {
    val newPos = pos.move(mv)
    RobotState(mv :: moves, newPos :: history)
  }
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
