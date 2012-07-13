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
end

