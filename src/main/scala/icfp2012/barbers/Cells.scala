package icfp2012.barbers

object Cell {
  val trampolines = ('A' to 'I').map { c => (c, Trampoline(c)) }.toMap
  val targets = ('0' to '9').map { c => (c, Target(c)) }.toMap
  val parser = Map('R' -> Robot,
        '*' -> Rock,
        'L' -> CLift,
        '.' -> Earth,
        '#' -> Wall,
        '\\' -> Lambda,
        'O' -> OLift,
        ' ' -> Empty) ++ trampolines ++ targets

  def parse(c : Char) : Cell = parser(c)
  def charOf(c : Cell) : Char = {
    c match {
      case Robot => 'R'
      case Rock => '*'
      case CLift => 'L'
      case Earth => '.'
      case Wall => '#'
      case Lambda => '\\'
      case OLift => 'O'
      case Empty => ' '
      case Trampoline(c) => c
      case Target(c) => c
    }
  }
}

sealed abstract class Cell
case object Robot extends Cell
case object Rock extends Cell
case object CLift extends Cell
case object Earth extends Cell
case object Wall extends Cell
case object Lambda extends Cell
case object OLift extends Cell
case object Empty extends Cell
case class Trampoline(c : Char) extends Cell
case class Target(c : Char) extends Cell
