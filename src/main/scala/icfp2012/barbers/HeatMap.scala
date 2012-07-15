package icfp2012.barbers

class HeatMap(map: TileMap){
  var cells = map.state.cells

  var state = cells.map {
    row =>
    row.map {
        cell => -1000
    }
  }

  override lazy val toString : String = {
    state.reverse
      .map { _.mkString(",")}
      .mkString("\n")
  }

}
