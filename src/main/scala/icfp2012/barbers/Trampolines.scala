package icfp2012.barbers

object TrampolineState {
  def parse(tokens : Iterable[(String, List[String])]) = new TrampolineState(
      tokens
        .filter { _._1 == "Trampoline" }
        .map { kv => parseTarget(kv._2)}
        .toMap
    )

  def parseTarget(line : List[String]) : (Trampoline, Target) = {
    val tramp = line(0)
    val target = line(2)
    (Trampoline(tramp.charAt(0)), Target(tramp.charAt(0)))
  }
}

case class TrampolineState(targetMap : Map[Trampoline, Target]) {
  def targetFor(tramp : Trampoline) : Target = targetMap(tramp)
  def jumpOn(tramp : Trampoline) : TrampolineState = {
    //Find all shared targets:
    val toInvalidate = targetMap.toList
      .groupBy { _._2 } // Key on target
      .apply(targetFor(tramp)) // Get the Seq[(Trampoline, Target)] which match this target
      .map { _._1 } // Get the other trampolines to remove
    new TrampolineState(targetMap -- toInvalidate)
  }
}
