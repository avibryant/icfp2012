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
  def heatOf(c : Cell) : Int = {
    c match {
      case Robot => -10000
      case Rock => -10000
      case CLift => -10000
      case Earth => -10000
      case Wall => -10000
      case Lambda => 25
      case OLift => 500
      case Empty => -10000
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
