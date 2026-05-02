require "test_helper"

class ForumTest < ActiveSupport::TestCase
  setup do
    @member = Member.create!(display_name: "alice", email: "alice@example.com", password: "password123")
  end

  def build_forum(overrides = {})
    Forum.new({ name: "ruby", created_by_member: @member }.merge(overrides))
  end

  test "valid forum is valid" do
    assert build_forum.valid?
  end

  test "name is required" do
    assert_not build_forum(name: nil).valid?
  end

  test "created_by_member is required" do
    assert_not build_forum(created_by_member: nil).valid?
  end

  test "nsfw defaults to false" do
    f = build_forum
    f.save!
    assert_equal false, f.nsfw
  end

  test "name uniqueness is case-insensitive" do
    build_forum.save!
    assert_not build_forum(name: "RUBY").valid?
  end

  test "belongs_to created_by_member" do
    assert_respond_to Forum.new, :created_by_member
  end

  test "has_many posts" do
    assert_respond_to Forum.new, :posts
  end
end
