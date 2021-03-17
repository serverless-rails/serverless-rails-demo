require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "users are created" do
    assert users(:one).valid?
  end
end
