require "minitest/autorun"
require_relative "./ripper_locals"

class RipperLocalsTest < Minitest::Test
  def get_locals(code)
    RipperLocals.find_locals(code)
  end

  def test_it_gets_local_assigns
    assert_equal ["b", "a", "c", "e", "d"], get_locals(<<~RUBY)
      def some_method
        a = b = 1
        c = a + b + 1
        d, e = *stuff
      end
    RUBY
  end

  def test_it_gets_positional_args_and_splats
    assert_equal ["a", "b"], get_locals(<<~RUBY)
      def some_method(a, b)
        a + z
      end
    RUBY

    assert_equal ["c", "d"], get_locals(<<~RUBY)
      def some_method(c = 1, d = 2, *)
        a + z
      end
    RUBY

    assert_equal ["c", "x"], get_locals(<<~RUBY)
      def some_method(c, *x)
        a + z
      end
    RUBY

    assert_equal ["a", "b", "c", "d"], get_locals(<<~RUBY)
      def some_method(a, b = 1, c = a, *d)
        a + z
      end
    RUBY
  end

  def test_it_gets_keyword_args_and_splats
    assert_equal ["a", "b"], get_locals(<<~RUBY)
      def some_method(a:, b:)
        a + z
      end
    RUBY

    assert_equal ["c", "d"], get_locals(<<~RUBY)
      def some_method(c: 1, d: 2, **)
        a + z
      end
    RUBY

    assert_equal ["c", "x"], get_locals(<<~RUBY)
      def some_method(c:, **x)
        a + z
      end
    RUBY

    assert_equal ["a", "b", "c", "d"], get_locals(<<~RUBY)
      def some_method(a:, b: 1, c: a, **d)
        a + z
      end
    RUBY
  end

  def test_it_gets_a_block_arg
    assert_equal ["hook"], get_locals(<<~RUBY)
      def some_method(&hook)
        a + z
      end
    RUBY
  end

  def test_it_doesnt_get_method_calls_or_assigns_to_self
    assert_equal [], get_locals(<<~RUBY)
      def some_method
        a(self.b)
        self.c = 1
      end
    RUBY
  end

  def test_no_locals
    assert_equal [], get_locals(<<~RUBY)
      def some_method
        @a + @b + 4
      end
    RUBY
  end

  def test_kitchen_sink
    assert_equal ["a", "b", "c", "d", "e", "g", "f", "i", "h"], get_locals(<<~RUBY)
      def some_method(a, b: 1, **c, &d)
        e = d.call
        f, g = *a
        h, *i = *a
      end
    RUBY
  end

  def test_block_scope_is_respected
    locals = get_locals(<<~RUBY)
      def some_method(z:)
        a = 1
        b.each do |x|
          c = x
        end
        d = y
      end
    RUBY
    assert_equal ["z", "a", "d"], locals
  end
end
