package icfp2012.barbers

import scala.collection.mutable._
import scala.annotation.tailrec

class MCTS(args : Array[String]) extends Algorithm(args) {
  val maxIterations = args(0).toInt
  val maxDepth = args(1).toInt
  val rand = new java.util.Random

  //todo: can we get the move list from the TileMap?
  class Node(val tm : TileMap, val moves : List[Move], parent : Node) {
    var count = 0.0d
    var totalScore = 0.0d
    var totalScore2 = 0.0d
    //todo- is there a cheaper representation?
    var children = Map[Move,Node]()

    def select : Node = {
      if(tm.gameState == Playing) {
        val untried = untriedMoves
        if(untried == Nil)
          bestChild.select
        else
          expand(untried)
      } else {
        this
      }
    }

    //magic, and can be tweaked
    val C = 1.0 / math.sqrt(2.0)
    val D = 1000.0

    def ucb = {
      val x = totalScore / count

      x + (C * math.sqrt(2.0 * math.log(parent.count) / count)) +
       math.sqrt((totalScore2 - (count*x*x) + D) / count)
    }

    val validMoves = List(Left, Down, Right, Up, Wait) 
    def untriedMoves = validMoves.filter{!children.contains(_)}

    def bestChild = children.values.maxBy(_.ucb)

    //todo: this might want to use heatmap
    def expand(moves : List[Move]) = createChild(moves.head)
    def createChild(mv : Move) = new Node(tm.move(mv), mv :: moves, this)

    //todo: this should definitely use heatmap
    def move = createChild(validMoves(rand.nextInt(5)))

    //todo: could probably be tailrec
    def simulate = {
      var depth = 0
      var best = this
      var step = this

      while(step.tm.gameState == Playing && depth <= maxDepth) {
        depth += 1
        step = step.move
        if(step.score > best.score)
          best = step
      }
      best
    }

    //todo: could use heatmap
    def score = tm.progress

    @tailrec
    final def update(score : Double) {
      totalScore += score
      totalScore2 += (score*score)
      count += 1
      if(parent != null) {
        if(!parent.children.contains(moves.head))
          parent.children(moves.head) = this
        parent.update(score)
      }
    }
  }

  var iterations = 0

  override def apply(tm : TileMap) = {
    val root = new Node(tm, Nil, null)
    var solution = tm
    while(iterations < maxIterations) {
      iterations += 1
      val result = root.select.simulate
      //todo - try updating just the select vs. the simulate result
      result.update(result.score)

      //todo - also update the result of compact
      if(result.tm.abortScore > solution.score) {
        if(result.tm.gameState == Winning)
          solution = compact(result.tm)
        else
          solution = result.tm.move(Abort)

        println("New solution:")
        println(solution)
      }
    }
    solution
  }

  //todo
  def compact(tm : TileMap) = tm
}

