package icfp2012.barbers

import scala.collection.mutable.HashMap

class AStar(ts : TileState, start : Position, targets : Set[Position]) {
  val goal = targets.toList.head

  var closedSet = Set[Position]()
  var openSet = Set(start)

  var gScore = HashMap(start -> 0)
  var fScore = HashMap(start -> estimate(start))

  def shortestDistance(maxIterations : Int) : Int = {
    var iterations = 0
    while(iterations < maxIterations) {
    //  println(fScore)
      if(openSet.size == 0)
        return 10000;
//      println("Open set size: " + openSet.size)
//      println("Closed set size: " + closedSet.size)

      iterate match {
        case Some(pos) => return fScore(pos)
        case _ => Unit
      }
      iterations += 1
    }
    println("max iterations reached")
    return fScore(openSet.minBy(fScore))
  }

  def iterate : Option[Position] = {
    val current = openSet.minBy(fScore)
//    println(current)
//    println(goal)
 //   println(estimate(current))
 //   println(gScore(current))

    if(targets.contains(current))
      return Some(current);

    openSet -= current
    closedSet += current
//    println(current.neighbors4)
    current.neighbors4.filter(p => ts(p) != Wall && p.x > 0 && p.y > 0).foreach {neighbor => 
   //   println("n")
      if(!closedSet.contains(neighbor)) {
//        println(neighbor)

        val tentativeGScore = gScore(current) + distanceBetween(current, neighbor)
   //     println("g")
  //      println(tentativeGScore)
        if(!openSet.contains(neighbor) || tentativeGScore < gScore(neighbor)) {
          openSet += neighbor
          gScore(neighbor) = tentativeGScore
          fScore(neighbor) = tentativeGScore + estimate(neighbor)
     //     println("f")
     //     println(fScore(neighbor))
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
      case (Rock, Rock) => 100
      case (_, Rock) => 10
      case (_, _) => 1
    }
  }
}