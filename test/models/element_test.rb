require "test_helper"

class ElementTest < ActiveSupport::TestCase
  test "原子番号と元素記号は重複不可" do
    element = elements(:hydrogen).dup
    assert_not element.valid?
    assert_includes element.errors[:atomic_number], "has already been taken"
    assert_includes element.errors[:symbol], "has already been taken"
  end
end
