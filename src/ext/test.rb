require 'fast_update'
require 'test/unit'

class TestFastUpdate < Test::Unit::TestCase

  def test_simple_rock_drop
    map = ["***", "   "]

    out = FastUpdate.update map

    assert_equal ["   ", "***"], out
  end
end

