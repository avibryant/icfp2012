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
    (Trampoline(tramp.charAt(0)), Target(target.charAt(0)))
  }
}

case class TrampolineState(targetMap : Map[Trampoline, Target]) {
  lazy val trampMap = targetMap.toList
      .groupBy { _._2 } // Key on target
      .mapValues { _.map { _._1 } } //Only keep the trampolines

  def targetFor(tramp : Trampoline) : Target = targetMap(tramp)
  def trampsFor(target : Target) : Seq[Trampoline] = trampMap(target)
  // Return the invalidated trampolines and the new state
  def jumpOn(tramp : Trampoline) : (Seq[Trampoline], TrampolineState) = {
    //Find all shared targets:
    val toInvalidate = trampsFor(targetFor(tramp))
    (toInvalidate, new TrampolineState(targetMap -- toInvalidate))
  }
}
