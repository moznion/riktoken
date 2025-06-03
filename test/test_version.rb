# frozen_string_literal: true

require_relative "test_helper"

class TestVersion < Minitest::Test
  def test_version_constant
    assert Riktoken.const_defined?(:VERSION)
    assert_match(/\A\d+\.\d+\.\d+\z/, Riktoken::VERSION)
  end

  def test_version_frozen
    assert Riktoken::VERSION.frozen?
  end
end
