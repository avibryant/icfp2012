package icfp2012.barbers

object Cell {
  val parser = Map('R' -> Robot,
        '*' -> Rock,
        'L' -> CLift,
        '.' -> Earth,
        '#' -> Wall,
        '\\' -> Lambda,
        'O' -> OLift,
        ' ' -> Empty)

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
      case OLift => 99
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

