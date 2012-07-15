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

  var moveCount = 0
  var nodeCount = 0

  var solution : TileMap = null

  //magic, and can be tweaked
  val C = 1.0 / math.sqrt(2.0)
  val D = 1
  def c = 1.0 - (math.exp(2 * solution.scoreRatio) / 5.0)

  class Node(val tm : TileMap, parent : Node) {
    var count = 0.0d
    var totalScore = 0.0d
    var totalScore2 = 0.0d

    var untriedMoves = tm.validMoves
    var children = List[Node]()

    def lastMove = tm.robotState.moves.head

    def select : Node = {
      if(tm.gameState == Playing) {
        if(untriedMoves == Nil)
          children.maxBy(_.ucb).select
        else
          addChild(createChild(untriedMoves.head))
      } else {
        this
      }
    }

    def ucb = {
      val x = totalScore / count

      x + (c * math.sqrt(2.0 * math.log(parent.count) / count))
      // + math.sqrt((totalScore2 - (count*x*x) + D) / count)
    }

    def createChild(mv : Move) = new Node(tm.move(mv), this)

    def simulate = {
      var depth = 0
      var best = this
      var step = this

      while(step.tm.gameState == Playing && depth <= maxDepth) {
        depth += 1
        moveCount += 1
        step = step.move
        if(step.score > best.score)
          best = step
      }
      best
    }

    def move = createChild(pickMove(tm.validMoves))

    //exponentially prefer earlier items in list
    def pickMove(moves : List[Move]) = {
      val n = moves.size
      if(math.random < c)
        moves(rand.nextInt(moves.size))
      else
        moves(0)
//      moves(n - 1 - math.log(rand.nextInt(math.pow(math.E, n).toInt) + 1).toInt)
    }

    def score = tm.progress

    @tailrec
    final def update(score : Double) {
      totalScore += score
      totalScore2 += (score*score)
      count += 1

      if(parent != null) {
        parent.ensureChild(this)
        parent.update(score)
      }
    }

    def ensureChild(child : Node) {
      if(untriedMoves.contains(child.lastMove))
        addChild(child)
    }

    def addChild(child : Node) = {
      nodeCount += 1
      untriedMoves = untriedMoves.filter(_ != child.lastMove)
      children = child :: children
      child
    }
  }

  override def apply(tm : TileMap) = {
    val startTime = System.currentTimeMillis
    val endTime = startTime + (1000 * maxTime)

    val root = new Node(tm, null)
    solution = tm

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
        println("Temperature: " + c)
        println("Progress score: " + candidate.progressScore)
        println("Move scores: " + candidate.moveScores)
        println("Elapsed time: " + (System.currentTimeMillis - startTime))
        println("Tree size: " + nodeCount)
        println("Moves/sec: " + (moveCount * 1000 / (System.currentTimeMillis - startTime)))
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

