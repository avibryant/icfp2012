package icfp2012.barbers

object Game {
  def apply(s : String) : Game = new Game(TileMap.parse(s))
}

// Import Move._ in the REPL to be able to treat strings/symbols/Char as Move
class Game(var tm : TileMap) {
  def move(mv : Move) {
    tm = tm.move(mv)
    println(tm)
  }
  def moves(mvs : Seq[Move]) { mvs.foreach { move } }
}
