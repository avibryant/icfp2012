require 'fast_update'
require 'test/unit'

class TestFastUpdate < Test::Unit::TestCase
  def assert_update(from, to)
    assert_equal to, FastUpdate.update(from)
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

