package icfp2012.barbers

case class WaterState(val level : Int, val floodingInterval : Int, val stepsToNextFlood : Int, val waterproof : Int, val stepsUnderwater : Int) {
  def update(robotState : RobotState) = {
    if(floodingInterval == 0)
      this
    else {
      val newStepsUnderwater = if(robotState.pos.y <= level)
                                  stepsUnderwater + 1
                               else
                                  0

      if(stepsToNextFlood == 0)
        WaterState(level + 1, floodingInterval, floodingInterval - 1, waterproof, newStepsUnderwater)
      else
        WaterState(level, floodingInterval, stepsToNextFlood - 1, waterproof, newStepsUnderwater)
    }
  }

  def botIsDrowned = stepsUnderwater > waterproof
}

object WaterState {
  def parseInt(tokens : Iterable[(String, List[String])], key : String, default : Int) = {
    tokens.find(_._1 == key) match {
      case(Some((_, List(v)))) => v.toInt
      case _ => default
    }
  }

  def parse(tokens : Iterable[(String, List[String])]) = {
    val level = parseInt(tokens, "Water", 0)
    val floodingInterval = parseInt(tokens, "Flooding", 0)
    val waterproof = parseInt(tokens, "Waterproof", 10)

    WaterState(level, floodingInterval, floodingInterval - 1, waterproof, 0)
  }
}