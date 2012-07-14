require 'fast_update'
require 'test/unit'

class TestFastUpdate < Test::Unit::TestCase
  def assert_update(from, to, dead = false)
    t, d = FastUpdate.update(from)
    assert_equal to, t
    assert_equal dead, d
  end

  def test_simple_rock_drop
    assert_update \
      ["***", "   "],
      ["   ", "***"]
  end

  def test_rocks_on_bottom
    assert_update \
      ["   ", "***"],
      ["   ", "***"]
  end

  def test_rocks_move_to_right
    assert_update \
      ["* ", "* "],
      ["  ", "**"]
  end

  def test_rocks_move_to_left
    assert_update \
      [" *", " *"],
      ["  ", "**"]
  end

  def test_rocks_slide_down_lambdas
    assert_update \
      ["* ", '\ '],
      ["  ", '\*']
  end

  def test_opens_lift_when_no_more_lambdas
    assert_update \
      ["L "],
      ["O "]
  end

  def test_falling_rocks_kill_robots
    assert_update \
      ["* ", "  ", "R "],
      ["  ", "* ", "R "],
      true
  end

 def test_left_rocks_kill_robots
    assert_update \
      [" *"," *", "R "],
      ["  ", "* ", "R*"],
      true
  end

 def test_right_rocks_kill_robots
    assert_update \
      ["* ", "* ", " R"],
      ["  ", " *", "*R"],
      true
  end
end

class TestUltraUpdate < Test::Unit::TestCase
  def assert_update(from, to)
    assert_equal to, FastUpdate.ultra_update(from, nil).first
  end

  def test_simple_rock_drop
    assert_update \
      ["***", "   "],
      ["   ", "***"]
  end

  def test_rocks_on_bottom
    assert_update \
      ["   ", "***"],
      ["   ", "***"]
  end

  def test_rocks_move_to_right
    assert_update \
      ["* ", "* "],
      ["  ", "**"]
  end

  def test_rocks_move_to_left
    assert_update \
      [" *", " *"],
      ["  ", "**"]
  end

  def test_rocks_slide_down_lambdas
    assert_update \
      ["* ", '\ '],
      ["  ", '\*']
  end

  def test_opens_lift_when_no_more_lambdas
    assert_update \
      ["L "],
      ["O "]
  end

  def test_uses_state_to_update_rocks
    map = ["* ", "  ", "  "]

    out, s = FastUpdate.ultra_update map, nil

    assert s, "No state output"

    assert_equal ["  ", "* ", "  "], out

    out, s = FastUpdate.ultra_update out, s

    assert_equal ["  ", "  ", "* "], out
  end

  def test_uses_state_to_update_lifts
    map = ['\ ', "L ", "  "]

    out, s = FastUpdate.ultra_update map, nil

    assert s, "No state output"

    assert_equal ['\ ', "L ", "  "], out

    map = ['  ', "L ", "  "]

    out, s = FastUpdate.ultra_update map, s

    assert_equal ["  ", "O ", "  "], out
  end
end

class TestFastUpdateMove < Test::Unit::TestCase
  def assert_move(row, col, dir, np, from, to)
    m, lambdas, pos = FastUpdate.move(from, row, col, dir)
    assert_equal to, m
    assert_equal np, pos
  end

  LEFT = 0
  RIGHT = 1
  UP = 2
  DOWN = 3

  def test_left
    assert_move 0, 1, LEFT, [0,0],
      [" R"],
      ["R "]
  end

  def test_ignores_left_into_rock
    assert_move 0, 1, LEFT, [0,1],
      ["*R"],
      ["*R"]
  end

  def test_right
    assert_move 0, 0, RIGHT, [0,1],
      ["R "],
      [" R"]
  end

  def test_ignores_right_into_rock
    assert_move 0, 1, RIGHT, [0,1],
      ["*R*"],
      ["*R*"]
  end

  def test_up
    assert_move 1, 1, UP, [0,1],
      ["  ", " R"],
      [" R", "  "]
  end

  def test_ignores_up_into_rock
    assert_move 1, 1, UP, [1,1],
      [" *", " R"],
      [" *", " R"]
  end

  def test_down
    assert_move 0, 1, DOWN, [1,1],
      [" R", "  "],
      ["  ", " R"]
  end

  def test_ignores_down_into_rock
    assert_move 0, 1, DOWN, [0,1],
      [" R", " *"],
      [" R", " *"]
  end

  def test_left_moves_rock
    assert_move 0, 2, LEFT, [0,1],
      [" *R"],
      ["*R "]
  end

  def test_right_moves_rock
    assert_move 0, 0, RIGHT, [0,1],
      ["R* "],
      [" R*"]
  end

  def test_counts_lambdas_captured
    from = ['\R']
    to =   ['R ']

    m, lambdas, np = FastUpdate.move(from, 0, 1, LEFT)
    assert_equal 1, lambdas
  end

  def test_ignores_close_lift
    assert_move 0, 0, RIGHT, [0,0],
      ["RL"],
      ["RL"]
  end

  def test_move_left_into_open_lift
    from = ["RO"]
    to =   [" R"]

    m, lambdas, np = FastUpdate.move(from, 0, 0, RIGHT)

    assert_equal to, m
    assert_equal -1, lambdas
    assert_equal [0,1], np
  end

  def test_move_right_into_open_lift
    from = ["OR"]
    to =   ["R "]

    m, lambdas, np = FastUpdate.move(from, 0, 1, LEFT)

    assert_equal to, m
    assert_equal -1, lambdas
    assert_equal [0,0], np
  end

  def test_move_up_into_open_lift
    from = ["O ", "R "]
    to =   ["R ", "  "]

    m, lambdas, np = FastUpdate.move(from, 1, 0, UP)

    assert_equal to, m
    assert_equal -1, lambdas
    assert_equal [0,0], np
  end

  def test_move_down_into_open_lift
    from = ["R ", "O "]
    to =   ["  ", "R "]

    m, lambdas, np = FastUpdate.move(from, 0, 0, DOWN)

    assert_equal to, m
    assert_equal -1, lambdas
    assert_equal [1,0], np
  end
end

class TestFastUpdateUltraMove < Test::Unit::TestCase
  LEFT = 0
  RIGHT = 1
  UP = 2
  DOWN = 3

  def test_left_moves_rock
    map = [" *R"]

    map, s = FastUpdate.ultra_update map, nil

    assert_equal [0,1], s[0][0]

    map, lambdas, np, s = FastUpdate.ultra_move map, 0, 2, LEFT, s

    assert_equal ["*R "], map
    assert_equal [0,0], s[0][0]
  end

  def test_right_moves_rock
    map = ["R* "]

    map, s = FastUpdate.ultra_update map, nil

    assert_equal [0,1], s[0][0]

    map, lambdas, np, s = FastUpdate.ultra_move map, 0, 0, RIGHT, s

    assert_equal [" R*"], map
    assert_equal [0,2], s[0][0]
  end
end
