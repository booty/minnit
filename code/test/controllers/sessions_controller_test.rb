require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(display_name: "alice", email: "alice@example.com", password: "password123")
  end

  test "GET /login renders form" do
    get login_url
    assert_response :success
  end

  test "POST /login with valid credentials sets session and redirects" do
    post login_url, params: { email: "alice@example.com", password: "password123" }
    assert_redirected_to root_path
    assert_equal @member.id, session[:member_id]
  end

  test "POST /login with wrong password re-renders form" do
    post login_url, params: { email: "alice@example.com", password: "wrong" }
    assert_response :unprocessable_entity
    assert_nil session[:member_id]
  end

  test "POST /login with unknown email re-renders form" do
    post login_url, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "DELETE /logout clears session and redirects" do
    post login_url, params: { email: "alice@example.com", password: "password123" }
    delete logout_url
    assert_redirected_to root_path
    assert_nil session[:member_id]
  end
end
