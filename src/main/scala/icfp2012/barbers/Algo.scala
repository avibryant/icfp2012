package icfp2012.barbers

import scala.annotation.tailrec

/*
 * To run your algorithm:
 * implement a subclass of Algorithm that has a constructor that takes an array of strings
 *
 * build the code:
 * sbt compile
 *
 * build the fat jar:
 * sbt assembly
 *
 * run the algorithm:
 * java -jar target/barbers-assembly-0.0.1.jar "icfp2012.barbers.RandomMover" < maps/contest1/base
 *
 * To play with your code at a REPL, type:
 * sbt console
 * you will need to
 * import icfp2012.barbers._
 * to have access to the classes
 */
object Algorithm {
  def apply(classname : String, args : Array[String]) : Algorithm = {
     Class.forName(classname)
        .getConstructor(classOf[Array[String]])
        .newInstance(args)
        .asInstanceOf[Algorithm]
  }

  def main(args : Array[String]) {
    val alg = apply(args(0), args.tail)
    println(solve(TileMap.parseStdin, alg))
  }

  @tailrec
  final def solve(tm : TileMap, a : Algorithm) : TileMap = {
    if (tm.gameState == Playing) {
      val (nt, na) = a.next(tm)
      solve(nt, na)
    }
    else {
      tm
    }
  }
}

abstract class Algorithm(args : Array[String]) {
  // Take a step, and return the next algorithm (possibly this) to run
  def next(tm : TileMap) : (TileMap, Algorithm)
}

class RandomMover(args : Array[String]) extends Algorithm(args) {
  val r = new java.util.Random
  val moves = Vector(Left,Right,Up,Down)

  def next(tm : TileMap) = {
    val nextTm = tm.move(moves(r.nextInt(4)))
    println(nextTm)
    (nextTm, this)
  }
}
