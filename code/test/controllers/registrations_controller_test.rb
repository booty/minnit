require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET /signup renders form" do
    get signup_url
    assert_response :success
  end

  test "POST /signup with valid params creates member and logs in" do
    assert_difference "Member.count", 1 do
      post signup_url, params: {
        member: { display_name: "newuser", email: "new@example.com", password: "password123" }
      }
    end
    assert_redirected_to root_path
    assert session[:member_id]
  end

  test "POST /signup with invalid params re-renders form" do
    post signup_url, params: { member: { display_name: "", email: "", password: "" } }
    assert_response :unprocessable_entity
  end

  test "POST /signup with duplicate email re-renders form" do
    Member.create!(display_name: "alice", email: "alice@example.com", password: "pass123")
    post signup_url, params: {
      member: { display_name: "bob", email: "alice@example.com", password: "pass123" }
    }
    assert_response :unprocessable_entity
  end
end
