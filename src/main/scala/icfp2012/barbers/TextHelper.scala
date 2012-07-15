package icfp2012.barbers

object TextHelper {
  def parseInt(tokens : Iterable[(String, List[String])], key : String, default : Int) = {
    tokens.find(_._1 == key) match {
      case(Some((_, List(v)))) => v.toInt
      case _ => default
    }
  }
}
