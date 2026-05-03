require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(display_name: "alice", email: "alice@example.com", password: "password123")
    @forum  = Forum.create!(name: "ruby", created_by_member: @member)
    @thread = Post.create!(member: @member, forum: @forum, title: "Hello world", body: "First post")
  end

  def log_in
    post login_url, params: { email: "alice@example.com", password: "password123" }
  end

  test "GET /posts/:id shows thread and its replies" do
    reply = Post.create!(member: @member, parent_post: @thread, body: "A reply")
    get post_url(@thread)
    assert_response :success
    assert_match @thread.title, response.body
    assert_match reply.body, response.body
  end

  test "POST /forums/:forum_id/posts redirects to login when not logged in" do
    post forum_posts_url(@forum), params: { post: { title: "T", body: "B" } }
    assert_redirected_to login_path
  end

  test "POST /forums/:forum_id/posts creates thread when logged in" do
    log_in
    assert_difference "Post.count", 1 do
      post forum_posts_url(@forum), params: { post: { title: "New thread", body: "Content here" } }
    end
    assert_redirected_to post_path(Post.last)
  end

  test "POST /forums/:forum_id/posts with invalid params re-renders forum show" do
    log_in
    post forum_posts_url(@forum), params: { post: { title: "", body: "" } }
    assert_response :unprocessable_entity
  end

  test "POST /posts/:post_id/replies redirects to login when not logged in" do
    post post_replies_url(@thread), params: { post: { body: "My reply" } }
    assert_redirected_to login_path
  end

  test "POST /posts/:post_id/replies creates reply when logged in" do
    log_in
    assert_difference "Post.count", 1 do
      post post_replies_url(@thread), params: { post: { body: "My reply" } }
    end
    assert_redirected_to post_path(@thread)
  end

  test "POST /posts/:post_id/replies with blank body re-renders show" do
    log_in
    post post_replies_url(@thread), params: { post: { body: "" } }
    assert_response :unprocessable_entity
  end
end
