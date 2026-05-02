require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @member = Member.create!(display_name: "alice", email: "alice@example.com", password: "password123")
    @forum  = Forum.create!(name: "ruby", created_by_member: @member)
  end

  def build_thread(overrides = {})
    Post.new({ member: @member, forum: @forum, title: "Hello world", body: "Body text" }.merge(overrides))
  end

  def build_reply(parent, overrides = {})
    Post.new({ member: @member, parent_post: parent, body: "A reply" }.merge(overrides))
  end

  # --- top-level thread ---

  test "valid top-level thread is valid" do
    assert build_thread.valid?
  end

  test "thread requires title" do
    assert_not build_thread(title: nil).valid?
  end

  test "thread requires forum" do
    assert_not build_thread(forum: nil).valid?
  end

  # --- reply ---

  test "valid reply is valid" do
    parent = build_thread
    parent.save!
    assert build_reply(parent).valid?
  end

  test "reply must not have a title" do
    parent = build_thread
    parent.save!
    assert_not build_reply(parent, title: "oops").valid?
  end

  test "reply must not have a forum" do
    parent = build_thread
    parent.save!
    assert_not build_reply(parent, forum: @forum).valid?
  end

  # --- shared ---

  test "member is required" do
    assert_not build_thread(member: nil).valid?
  end

  test "body is required" do
    assert_not build_thread(body: nil).valid?
  end

  test "cannot have both forum_id and parent_post_id" do
    parent = build_thread
    parent.save!
    assert_not Post.new(member: @member, forum: @forum, parent_post: parent, title: "T", body: "B").valid?
  end

  test "must have forum_id or parent_post_id" do
    assert_not Post.new(member: @member, body: "B").valid?
  end

  # --- associations ---

  test "belongs_to member" do
    assert_respond_to Post.new, :member
  end

  test "belongs_to forum (optional)" do
    assert_respond_to Post.new, :forum
  end

  test "belongs_to parent_post (optional)" do
    assert_respond_to Post.new, :parent_post
  end

  test "has_many replies" do
    assert_respond_to Post.new, :replies
  end

  # --- soft delete scope ---

  test "active scope excludes deleted records" do
    parent = build_thread
    parent.save!
    parent.update!(deleted_at: Time.current)
    assert_not Post.active.include?(parent)
  end
end
