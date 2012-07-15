package icfp2012.barbers

import scala.collection.mutable._
import scala.annotation.tailrec

/*
Args: max number of seconds to run, max depth to simulate
Example:
java -jar target/barbers-assembly-0.0.1.jar icfp2012.barbers.MCTS 5 30 < maps/contest1/base
*/
class MCTS(args : Array[String]) extends Algorithm(args) {
  val maxTime = args(0).toInt
  val maxDepth = args(1).toInt
  val rand = new java.util.Random

  class Node(val tm : TileMap, parent : Node) {
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
    def createChild(mv : Move) = new Node(tm.move(mv), this)

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
        val lastMove = tm.robotState.moves.head
        if(!parent.children.contains(lastMove))
          parent.children(lastMove) = this
        parent.update(score)
      }
    }
  }

  override def apply(tm : TileMap) = {
    val startTime = System.currentTimeMillis
    val endTime = startTime + (1000 * maxTime)

    val root = new Node(tm, null)
    var solution = tm

    while(System.currentTimeMillis < endTime) {
      val selection = root.select
      val result = selection.simulate
      //todo - try updating just the selection vs. the simulate result
      result.update(result.score)

      var candidate = result.tm
      if(candidate.abortScore > solution.score) {
        if(candidate.gameState == Winning)
          solution = compact(root.tm, candidate)
        else
          solution = candidate.move(Abort)

        //todo - if compacted, create nodes for and update solution?

        println("New solution:")
        println(solution)
        println("Elapsed time: " + (System.currentTimeMillis - startTime))
      }
    }
    solution
  }

  @tailrec
  final def compact(root : TileMap, tm : TileMap) : TileMap = {
    var best = tm
    val movesWithIndex = tm.robotState.moves.reverse.zipWithIndex
    movesWithIndex.foreach { case (m, i) => {
      var step = root
      movesWithIndex.foreach { case(n, j) => {
        if(i != j)
          step = step.move(n)
      }}

      if(step.score >= best.score)
        best = step
    }}

    if(best != tm)
      compact(root, best)
    else
      tm
  }
}

