require "test_helper"

class ForumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(display_name: "alice", email: "alice@example.com", password: "password123")
    @forum  = Forum.create!(name: "ruby", created_by_member: @member)
  end

  def log_in
    post login_url, params: { email: "alice@example.com", password: "password123" }
  end

  test "GET /forums lists forums" do
    get forums_url
    assert_response :success
    assert_match "ruby", response.body
  end

  test "GET /forums/:id shows forum and its threads" do
    get forum_url(@forum)
    assert_response :success
    assert_match @forum.name, response.body
  end

  test "GET /forums/new redirects to login when not logged in" do
    get new_forum_url
    assert_redirected_to login_path
  end

  test "GET /forums/new renders form when logged in" do
    log_in
    get new_forum_url
    assert_response :success
  end

  test "POST /forums redirects to login when not logged in" do
    post forums_url, params: { forum: { name: "newstuff", nsfw: false } }
    assert_redirected_to login_path
  end

  test "POST /forums creates forum when logged in" do
    log_in
    assert_difference "Forum.count", 1 do
      post forums_url, params: { forum: { name: "newstuff", nsfw: false } }
    end
    assert_redirected_to forum_path(Forum.last)
  end

  test "POST /forums with invalid params re-renders form" do
    log_in
    post forums_url, params: { forum: { name: "", nsfw: false } }
    assert_response :unprocessable_entity
  end
end
