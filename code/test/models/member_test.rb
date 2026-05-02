require "test_helper"

class MemberTest < ActiveSupport::TestCase
  def build_member(overrides = {})
    Member.new({ display_name: "alice", email: "alice@example.com", password: "password123" }.merge(overrides))
  end

  test "valid member is valid" do
    assert build_member.valid?
  end

  test "display_name is required" do
    assert_not build_member(display_name: nil).valid?
  end

  test "email is required" do
    assert_not build_member(email: nil).valid?
  end

  test "password is required" do
    assert_not Member.new(display_name: "alice", email: "alice@example.com").valid?
  end

  test "access_level defaults to 100" do
    m = build_member
    m.save!
    assert_equal 100, m.access_level
  end

  test "access_level must be 100, 200, or 300" do
    assert_not build_member(access_level: 50).valid?
    assert_not build_member(access_level: 150).valid?
    assert build_member(access_level: 100).valid?
    assert build_member(access_level: 200).valid?
    assert build_member(access_level: 300).valid?
  end

  test "display_name uniqueness is case-insensitive" do
    build_member.save!
    assert_not build_member(display_name: "ALICE", email: "other@example.com").valid?
  end

  test "email uniqueness is case-insensitive" do
    build_member.save!
    assert_not build_member(display_name: "bob", email: "ALICE@EXAMPLE.COM").valid?
  end

  test "has_many posts" do
    assert_respond_to Member.new, :posts
  end

  test "has_many created_forums" do
    assert_respond_to Member.new, :created_forums
  end
end
