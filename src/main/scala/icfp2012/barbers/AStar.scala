package icfp2012.barbers

import scala.collection.mutable.HashMap
import scala.annotation.tailrec

class AStar(tm : TileMap, start : Position, targets : Set[Position]) {
  val goals =
    if(targets.size < 100)
      targets
    else
      tm.nearbyLambdas(20).toSet

  var closedSet = Set[Position]()
  var openSet = Set(start)

  var gScore = HashMap(start -> 0)
  var fScore = HashMap(start -> estimate(start))

  val cameFrom = HashMap[Position,Position]()

  def closestTarget : Position = {
    var iterations = 0
    while(iterations < 500) {
      if(openSet.size == 0)
        return targets.toList.head;

      iterate match {
        case Some(pos) => return pos
        case _ => Unit
      }
      iterations += 1
    }
    openSet.minBy(fScore)
  }

  def shortestDistanceTo(pos : Position) = fScore.getOrElse(pos, 10000)

  final def pathTo(pos: Position) : List[Position] = {
    cameFrom.get(pos) match {
      case Some(p2) => pos :: pathTo(p2)
      case None => Nil
    }
  }

  def randomMinimumFromOpenSet = {
    val min = openSet.minBy(fScore)
    val minScore = fScore(min)
    val allMin = openSet
      .filter { fScore(_) == minScore }
      .toIndexedSeq
    val idx = (allMin.size * scala.math.random).toInt
    allMin(idx)
  }

  def iterate : Option[Position] = {
    val current = randomMinimumFromOpenSet
    if(goals.contains(current))
      return Some(current);

    openSet -= current
    closedSet += current
    neighbors(current).foreach {neighbor =>
      if(!closedSet.contains(neighbor)) {

        val tentativeGScore = gScore(current) + distanceBetween(current, neighbor)
        if(!openSet.contains(neighbor) || tentativeGScore < gScore(neighbor)) {
          openSet += neighbor
          cameFrom(neighbor) = current
          gScore(neighbor) = tentativeGScore
          fScore(neighbor) = tentativeGScore + estimate(neighbor)
        }
      }
    }

    return None;
  }

  def neighbors(pos : Position) = {
    val n4 = tm.state(pos) match {
      case tramp@Trampoline(_) => tm.cellPositions(tm.trampState.targetFor(tramp))
      case _ => pos.neighbors4
    }
    n4.filter(p => tm.state(p) != Wall && p.x >= 0 && p.y >= 0)
  }

  def estimate(pos : Position) : Int = {
    goals.map(estimate(pos, _)).min
  }

  def estimate(from : Position, to : Position) : Int = {
    math.abs(from.x - to.x) + math.abs(from.y - to.y)
  }

  def distanceBetween(cell : Position, neighbor : Position) = {
    val baseDistance = (tm.state(cell), tm.state(neighbor)) match {
      case (_, Wall) => 10000
      case (Wall, _) => 10000
      case (Rock, Rock) => 100
      case (_, Rock) => 10
      case (Rock, _) => 5
      case (_, _) => 1
    }
    if(neighbor.y <= tm.waterState.level)
      baseDistance + 5
    else
      baseDistance
  }
}
