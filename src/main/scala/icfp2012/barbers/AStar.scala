package icfp2012.barbers

import scala.collection.mutable.HashMap

class AStar(ts : TileState, start : Position, targets : Set[Position]) {
  val goal = targets.toList.head

  var closedSet = Set[Position]()
  var openSet = Set(start)

  var gScore = HashMap(start -> 0)
  var fScore = HashMap(start -> estimate(start))

  def shortestDistance : Int = {
    var iterations = 0
    while(iterations < 500) {
      if(openSet.size == 0)
        return 10000;

      iterate match {
        case Some(pos) => return fScore(pos)
        case _ => Unit
      }
      iterations += 1
    }
    fScore(openSet.minBy(fScore))
  }

  def iterate : Option[Position] = {
    val current = openSet.minBy(fScore)
    if(targets.contains(current))
      return Some(current);

    openSet -= current
    closedSet += current
    current.neighbors4.filter(p => ts(p) != Wall && p.x >= 0 && p.y >= 0).foreach {neighbor => 
      if(!closedSet.contains(neighbor)) {

        val tentativeGScore = gScore(current) + distanceBetween(current, neighbor)
        if(!openSet.contains(neighbor) || tentativeGScore < gScore(neighbor)) {
          openSet += neighbor
          gScore(neighbor) = tentativeGScore
          fScore(neighbor) = tentativeGScore + estimate(neighbor)
        }
      }
    }

    return None;
  }

  def estimate(pos : Position) : Int = {
    targets.map(estimate(pos, _)).min
  }

  def estimate(from : Position, to : Position) : Int = {
    math.abs(from.x - to.x) + math.abs(from.y - to.y)
  }

  def distanceBetween(cell : Position, neighbor : Position) = {
    (ts(cell), ts(neighbor)) match {
      case (_, Wall) => 10000
      case (Wall, _) => 10000
      case (Rock, Rock) => 100
      case (_, Rock) => 10
      case (Rock, _) => 5
      case (_, _) => 1
    }
  }
}