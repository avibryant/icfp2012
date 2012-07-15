package icfp2012.barbers

case class WaterState(val level : Int, val floodingInterval : Int, val stepsToNextFlood : Int, val waterproof : Int) {

}

object WaterState {
  def parseInt(tokens : Iterable[(String, List[String])], key : String, default : Int) = {
    tokens.find(_._1 == "Water") match {
      case(Some((_, List(v)))) => v.toInt
      case _ => default
    }
  }

  def parse(tokens : Iterable[(String, List[String])]) = {
    val level = parseInt(tokens, "Water", 0)
    val floodingInterval = parseInt(tokens, "Flooding", 0)
    val waterproof = parseInt(tokens, "Waterproof", 10)

    WaterState(level, floodingInterval, floodingInterval, waterproof)
  }
}