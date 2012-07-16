package icfp2012.barbers

import scala.annotation.tailrec
import scala.collection.immutable.Queue

import sun.misc.{Signal, SignalHandler}

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

  def isQuiet(args : Array[String]) : Boolean = {
    args.size >= 2 && args(1) == "--quiet"
  }

  def main(args : Array[String]) {
    val quiet = isQuiet(args)
    val alg = apply(args(0), if (quiet) args.tail.tail else args.tail )
    // pass the sigint to the algorithms
    Signal.handle(new Signal("INT"), new SignalHandler() {
      override def handle(sig : Signal) { alg.interrupt }
    })
    val startTm = TileMap.parseStdin
    if(!quiet) {
      println("-------------")
      println("-   INPUT   -")
      println("-------------")
      println(startTm)
    }
    //Actually run here:
    val finalTm = alg(startTm)
    if(!quiet) {
      println("-------------")
      println("- SOLUTION: -")
      println("-------------")
      println(finalTm)
      println(finalTm.score.toString + "\t" + finalTm.robotState.moves.size)
    }
    println(finalTm.robotState.moveString)
  }

}

abstract class Algorithm(args : Array[String]) {
  val lock = new Object
  var timeOfSigInt : Option[Long] = None

  def interrupt {
    lock.synchronized {
      if (timeOfSigInt.isEmpty) {
        timeOfSigInt = Some(System.currentTimeMillis)
      }
    }
  }

  // How long was it since we got the interrupt
  def msSinceInterrupt : Option[Long] = lock.synchronized {
    timeOfSigInt.map { ts => System.currentTimeMillis - ts }
  }

  def apply(tm : TileMap) : TileMap
}

abstract class IterativeAlgorithm(args : Array[String]) extends Algorithm(args) {
  def apply(tm : TileMap) : TileMap = solve(tm)

  // Take a step, and return a list of next steps and algorithms to run.
  def next(tm : TileMap) : (TileMap, IterativeAlgorithm)

  @tailrec
  final def solve(tm : TileMap, a : IterativeAlgorithm = this) : TileMap = {
    if (tm.gameState == Playing) {
      val (nt, na) = a.next(tm)
      solve(nt, na)
    }
    else {
      tm
    }
  }
}

class RandomMover(args : Array[String]) extends IterativeAlgorithm(args) {
  val r = new java.util.Random
  val moves = Vector(Left,Right,Up,Down)

  def next(tm : TileMap) = {
    val nextMove = if(tm.robotState.beardNeighbors(tm.beardPos).size > 0 && tm.razorCount > 0) {
      Shave
    } else {
      moves(r.nextInt(4))
    }
    val nextTm = tm.move(nextMove)
    println(nextTm)
    (nextTm, this)
  }
}

class Animate(args : Array[String]) extends IterativeAlgorithm(args) {

  def next(tm : TileMap) = {
    if(args(0).size > 0) {
      val nextTm = tm.move(Move.parse(args(0).head))
      println(nextTm)
      (nextTm, new Animate(Array(args(0).tail)))
    } else {
      (tm.move(Abort), this)
    }
  }
}

class Greedy(args : Array[String]) extends Algorithm(args) {
  val moves = List(Left,Right,Up,Down,Abort)

  val topNMaps = args(0).toInt
  val animate = if (args.size > 1) args(1).toBoolean else false

  def apply(tm : TileMap) : TileMap = breadthFirst(Queue(tm))

  def childrenOf(tm : TileMap) : List[TileMap] = {
    if(tm.gameState == Playing) {
      moves.map { tm.move(_) }
    }
    else {
      Nil
    }
  }

  @tailrec
  private def breadthFirst(q : Queue[TileMap],
    top : List[TileMap] = List[TileMap](),
    visited : Set[TileMap] = Set[TileMap]())
    : TileMap = {
    if (q.isEmpty) {
      //We are done, now take the best TileMap:
      top.maxBy { _.score }
    }
    else {
      val qh = q.head
      //println(qh)
      // Obviously wasteful, but this is a demo:
      val newTop = (qh :: top).sortBy { tm => -(tm.score) }.take(topNMaps)
      val newToVisit = if (newTop != top) {
        //We have just found a new possible best:
        // print it:
        if (animate) {
          println(qh)
        }
        childrenOf(qh).filterNot { visited }
      }
      else {
        //Nothing new, ignore the children:
        Nil
      }
      breadthFirst(q.tail ++ newToVisit, newTop, visited + qh)
    }
  }
}
