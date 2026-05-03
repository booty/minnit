# Prototype UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up controllers, views, routes, layout, and seeds so a user can register, log in, browse forums, create forums, create threads, and reply to threads.

**Architecture:** Classic server-side Rails, full-page redirects, `session[:member_id]` auth. No Turbo enhancements. All commands run from `code/` (the Rails root).

**Tech Stack:** Rails 8.1 · Ruby 4.0.1 · SQLite3 · ERB views · Minitest integration tests

---

## File Map

**Create:**
- `code/config/routes.rb` (replace)
- `code/app/controllers/registrations_controller.rb`
- `code/app/controllers/sessions_controller.rb`
- `code/app/controllers/forums_controller.rb`
- `code/app/controllers/posts_controller.rb`
- `code/app/views/registrations/new.html.erb`
- `code/app/views/sessions/new.html.erb`
- `code/app/views/forums/index.html.erb`
- `code/app/views/forums/show.html.erb`
- `code/app/views/forums/new.html.erb`
- `code/app/views/posts/show.html.erb`
- `code/test/controllers/registrations_controller_test.rb`
- `code/test/controllers/sessions_controller_test.rb`
- `code/test/controllers/forums_controller_test.rb`
- `code/test/controllers/posts_controller_test.rb`

**Modify:**
- `code/app/controllers/application_controller.rb`
- `code/app/views/layouts/application.html.erb`
- `code/db/seeds.rb`

---

## Task 1: Routes *(haiku)*

**Files:**
- Modify: `code/config/routes.rb`

- [ ] **Step 1: Write routes**

Replace the entire contents of `code/config/routes.rb`:

```ruby
Rails.application.routes.draw do
  root "forums#index"

  get    "signup",  to: "registrations#new",  as: :signup
  post   "signup",  to: "registrations#create"
  get    "login",   to: "sessions#new",       as: :login
  post   "login",   to: "sessions#create"
  delete "logout",  to: "sessions#destroy",   as: :logout

  resources :forums, only: [:index, :show, :new, :create] do
    resources :posts, only: [:create]
  end

  resources :posts, only: [:show] do
    resources :posts, only: [:create], path: :replies, as: :replies
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 2: Verify routes exist**

```bash
bin/rails routes | grep -E "signup|login|logout|forums|posts|replies"
```

Expected output includes:
```
          signup GET    /signup                        registrations#new
                 POST   /signup                        registrations#create
           login GET    /login                         sessions#new
                 POST   /login                         sessions#create
          logout DELETE /logout                        sessions#destroy
          forums GET    /forums                        forums#index
       new_forum GET    /forums/new                    forums#new
                 POST   /forums                        forums#create
           forum GET    /forums/:id                    forums#show
     forum_posts POST   /forums/:forum_id/posts        posts#create
            post GET    /posts/:id                     posts#show
    post_replies POST   /posts/:post_id/replies        posts#create
```

- [ ] **Step 3: Commit**

```bash
git add code/config/routes.rb
git commit -m "Add prototype routes"
```

---

## Task 2: ApplicationController auth helpers *(sonnet)*

**Files:**
- Modify: `code/app/controllers/application_controller.rb`

> Note: `current_member` and `require_login` are exercised and verified by controller tests in Tasks 5 and 6. No standalone test is added here since there are no protected routes until Task 5.

- [ ] **Step 1: Add auth helpers**

Replace `code/app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_member

  private

  def current_member
    @current_member ||= Member.find_by(id: session[:member_id]) if session[:member_id]
  end

  def require_login
    redirect_to login_path, notice: "Please log in." unless current_member
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add code/app/controllers/application_controller.rb
git commit -m "Add current_member and require_login helpers"
```

---

## Task 3: RegistrationsController *(sonnet)*

**Files:**
- Create: `code/app/controllers/registrations_controller.rb`
- Create: `code/app/views/registrations/new.html.erb`
- Create: `code/test/controllers/registrations_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `code/test/controllers/registrations_controller_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails db:test:prepare test test/controllers/registrations_controller_test.rb
```

Expected: 4 errors — `NameError: uninitialized constant RegistrationsController`

- [ ] **Step 3: Create controller**

Create `code/app/controllers/registrations_controller.rb`:

```ruby
class RegistrationsController < ApplicationController
  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params)
    if @member.save
      session[:member_id] = @member.id
      redirect_to root_path, notice: "Welcome, #{@member.display_name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def member_params
    params.require(:member).permit(:display_name, :email, :password)
  end
end
```

- [ ] **Step 4: Create view**

Create `code/app/views/registrations/new.html.erb`:

```erb
<h1>Sign up</h1>

<%= form_with model: @member, url: signup_path do |f| %>
  <% if @member.errors.any? %>
    <ul>
      <% @member.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
    </ul>
  <% end %>

  <div>
    <%= f.label :display_name %>
    <%= f.text_field :display_name %>
  </div>
  <div>
    <%= f.label :email %>
    <%= f.email_field :email %>
  </div>
  <div>
    <%= f.label :password %>
    <%= f.password_field :password %>
  </div>
  <%= f.submit "Sign up" %>
<% end %>

<p>Already have an account? <%= link_to "Log in", login_path %></p>
```

- [ ] **Step 5: Run tests — expect green**

```bash
bin/rails test test/controllers/registrations_controller_test.rb
```

Expected: `4 runs, 4 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add code/app/controllers/registrations_controller.rb \
        code/app/views/registrations/ \
        code/test/controllers/registrations_controller_test.rb
git commit -m "Add RegistrationsController with signup flow"
```

---

## Task 4: SessionsController *(sonnet)*

**Files:**
- Create: `code/app/controllers/sessions_controller.rb`
- Create: `code/app/views/sessions/new.html.erb`
- Create: `code/test/controllers/sessions_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `code/test/controllers/sessions_controller_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails test test/controllers/sessions_controller_test.rb
```

Expected: 5 errors — `NameError: uninitialized constant SessionsController`

- [ ] **Step 3: Create controller**

Create `code/app/controllers/sessions_controller.rb`:

```ruby
class SessionsController < ApplicationController
  def new
  end

  def create
    member = Member.active.find_by("LOWER(email) = LOWER(?)", params[:email])
    if member&.authenticate(params[:password])
      session[:member_id] = member.id
      redirect_to root_path, notice: "Welcome back, #{member.display_name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:member_id)
    redirect_to root_path, notice: "Logged out."
  end
end
```

- [ ] **Step 4: Create view**

Create `code/app/views/sessions/new.html.erb`:

```erb
<h1>Log in</h1>

<%= form_with url: login_path do |f| %>
  <div>
    <%= f.label :email, "Email" %>
    <%= f.email_field :email %>
  </div>
  <div>
    <%= f.label :password, "Password" %>
    <%= f.password_field :password %>
  </div>
  <%= f.submit "Log in" %>
<% end %>

<p>New here? <%= link_to "Sign up", signup_path %></p>
```

- [ ] **Step 5: Run tests — expect green**

```bash
bin/rails test test/controllers/sessions_controller_test.rb
```

Expected: `5 runs, 5 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add code/app/controllers/sessions_controller.rb \
        code/app/views/sessions/ \
        code/test/controllers/sessions_controller_test.rb
git commit -m "Add SessionsController with login/logout flow"
```

---

## Task 5: Layout *(haiku)*

**Files:**
- Modify: `code/app/views/layouts/application.html.erb`

- [ ] **Step 1: Update layout**

Replace the `<body>` contents of `code/app/views/layouts/application.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Minnit" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <nav>
      <%= link_to "Minnit", root_path %> |
      <%= link_to "Forums", forums_path %>
      <% if current_member %>
        | <%= current_member.display_name %>
        | <%= button_to "Log out", logout_path, method: :delete %>
      <% else %>
        | <%= link_to "Log in", login_path %>
        | <%= link_to "Sign up", signup_path %>
      <% end %>
    </nav>

    <% if notice %>
      <p><strong><%= notice %></strong></p>
    <% end %>
    <% if alert %>
      <p><strong><%= alert %></strong></p>
    <% end %>

    <%= yield %>
  </body>
</html>
```

- [ ] **Step 2: Verify syntax**

```bash
bin/rails runner "puts 'layout ok'"
```

Expected: `layout ok`

- [ ] **Step 3: Commit**

```bash
git add code/app/views/layouts/application.html.erb
git commit -m "Add nav bar to application layout"
```

---

## Task 6: ForumsController *(sonnet)*

**Files:**
- Create: `code/app/controllers/forums_controller.rb`
- Create: `code/app/views/forums/index.html.erb`
- Create: `code/app/views/forums/show.html.erb`
- Create: `code/app/views/forums/new.html.erb`
- Create: `code/test/controllers/forums_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `code/test/controllers/forums_controller_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails test test/controllers/forums_controller_test.rb
```

Expected: 7 errors — `NameError: uninitialized constant ForumsController`

- [ ] **Step 3: Create controller**

Create `code/app/controllers/forums_controller.rb`:

```ruby
class ForumsController < ApplicationController
  before_action :require_login, only: [:new, :create]

  def index
    @forums = Forum.active.order(:name)
  end

  def show
    @forum   = Forum.active.find(params[:id])
    @threads = @forum.posts.active.where(parent_post_id: nil).order(created_at: :desc)
    @post    = Post.new
  end

  def new
    @forum = Forum.new
  end

  def create
    @forum = Forum.new(forum_params.merge(created_by_member: current_member))
    if @forum.save
      redirect_to @forum, notice: "Forum created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def forum_params
    params.require(:forum).permit(:name, :nsfw)
  end
end
```

- [ ] **Step 4: Create forums/index view**

Create `code/app/views/forums/index.html.erb`:

```erb
<h1>Forums</h1>

<% if current_member %>
  <%= link_to "New Forum", new_forum_path %>
<% end %>

<table>
  <thead>
    <tr>
      <th>Forum</th>
      <th>Created by</th>
    </tr>
  </thead>
  <tbody>
    <% @forums.each do |forum| %>
      <tr>
        <td>
          <%= link_to forum.name, forum %>
          <%= "[NSFW]" if forum.nsfw %>
        </td>
        <td><%= forum.created_by_member.display_name %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

- [ ] **Step 5: Create forums/show view**

Create `code/app/views/forums/show.html.erb`:

```erb
<h1>
  <%= @forum.name %>
  <%= "[NSFW]" if @forum.nsfw %>
</h1>
<p>Created by <%= @forum.created_by_member.display_name %></p>

<h2>Threads</h2>

<% if @threads.empty? %>
  <p>No threads yet.</p>
<% else %>
  <ul>
    <% @threads.each do |thread| %>
      <li>
        <%= link_to thread.title, thread %>
        — by <%= thread.member.display_name %>
        at <%= thread.created_at.strftime("%Y-%m-%d %H:%M") %>
        (<%= thread.replies.active.count %> replies)
      </li>
    <% end %>
  </ul>
<% end %>

<% if current_member %>
  <h2>New Thread</h2>
  <%= form_with model: @post, url: forum_posts_path(@forum) do |f| %>
    <% if @post.errors.any? %>
      <ul>
        <% @post.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    <% end %>
    <div>
      <%= f.label :title %>
      <%= f.text_field :title %>
    </div>
    <div>
      <%= f.label :body %>
      <%= f.text_area :body %>
    </div>
    <%= f.submit "Post Thread" %>
  <% end %>
<% else %>
  <p><%= link_to "Log in", login_path %> to post a thread.</p>
<% end %>
```

- [ ] **Step 6: Create forums/new view**

Create `code/app/views/forums/new.html.erb`:

```erb
<h1>New Forum</h1>

<%= form_with model: @forum do |f| %>
  <% if @forum.errors.any? %>
    <ul>
      <% @forum.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
    </ul>
  <% end %>

  <div>
    <%= f.label :name %>
    <%= f.text_field :name %>
  </div>
  <div>
    <%= f.label :nsfw, "NSFW?" %>
    <%= f.check_box :nsfw %>
  </div>
  <%= f.submit "Create Forum" %>
<% end %>
```

- [ ] **Step 7: Run tests — expect green**

```bash
bin/rails db:test:prepare test test/controllers/forums_controller_test.rb
```

Expected: `7 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 8: Commit**

```bash
git add code/app/controllers/forums_controller.rb \
        code/app/views/forums/ \
        code/test/controllers/forums_controller_test.rb
git commit -m "Add ForumsController with index, show, new, create"
```

---

## Task 7: PostsController *(sonnet)*

**Files:**
- Create: `code/app/controllers/posts_controller.rb`
- Create: `code/app/views/posts/show.html.erb`
- Create: `code/test/controllers/posts_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `code/test/controllers/posts_controller_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails test test/controllers/posts_controller_test.rb
```

Expected: 7 errors — `NameError: uninitialized constant PostsController`

- [ ] **Step 3: Create controller**

Create `code/app/controllers/posts_controller.rb`:

```ruby
class PostsController < ApplicationController
  before_action :require_login, only: [:create]

  def show
    @post    = Post.active.where(parent_post_id: nil).find(params[:id])
    @replies = @post.replies.active.order(created_at: :asc)
    @reply   = Post.new
  end

  def create
    if params[:forum_id]
      create_thread
    else
      create_reply
    end
  end

  private

  def create_thread
    @forum = Forum.active.find(params[:forum_id])
    @post  = Post.new(thread_params.merge(forum: @forum, member: current_member))
    if @post.save
      redirect_to @post, notice: "Thread created."
    else
      @threads = @forum.posts.active.where(parent_post_id: nil).order(created_at: :desc)
      render "forums/show", status: :unprocessable_entity
    end
  end

  def create_reply
    @post  = Post.active.where(parent_post_id: nil).find(params[:post_id])
    @reply = Post.new(reply_params.merge(parent_post: @post, member: current_member))
    if @reply.save
      redirect_to @post, notice: "Reply posted."
    else
      @replies = @post.replies.active.order(created_at: :asc)
      render :show, status: :unprocessable_entity
    end
  end

  def thread_params
    params.require(:post).permit(:title, :body)
  end

  def reply_params
    params.require(:post).permit(:body)
  end
end
```

- [ ] **Step 4: Create posts/show view**

Create `code/app/views/posts/show.html.erb`:

```erb
<% content_for :title, @post.title %>

<p><%= link_to "← #{@post.forum.name}", @post.forum %></p>

<h1><%= @post.title %></h1>
<p>
  Posted by <strong><%= @post.member.display_name %></strong>
  at <%= @post.created_at.strftime("%Y-%m-%d %H:%M") %>
</p>
<p><%= @post.body %></p>

<hr>

<h2>Replies (<%= @replies.count %>)</h2>

<% if @replies.empty? %>
  <p>No replies yet.</p>
<% end %>

<% @replies.each do |reply| %>
  <div>
    <strong><%= reply.member.display_name %></strong>
    <span><%= reply.created_at.strftime("%Y-%m-%d %H:%M") %></span>
    <p><%= reply.body %></p>
  </div>
<% end %>

<% if current_member %>
  <h2>Post a Reply</h2>
  <%= form_with model: @reply, url: post_replies_path(@post) do |f| %>
    <% if @reply.errors.any? %>
      <ul>
        <% @reply.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    <% end %>
    <div>
      <%= f.label :body, "Your reply" %>
      <%= f.text_area :body %>
    </div>
    <%= f.submit "Post Reply" %>
  <% end %>
<% else %>
  <p><%= link_to "Log in", login_path %> to post a reply.</p>
<% end %>
```

- [ ] **Step 5: Run tests — expect green**

```bash
bin/rails db:test:prepare test test/controllers/posts_controller_test.rb
```

Expected: `7 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Run the full test suite**

```bash
bin/rails test
```

Expected: `32 runs, 0 failures, 0 errors` (model tests from previous slice + all controller tests)

- [ ] **Step 7: Commit**

```bash
git add code/app/controllers/posts_controller.rb \
        code/app/views/posts/ \
        code/test/controllers/posts_controller_test.rb
git commit -m "Add PostsController with thread and reply creation"
```

---

## Task 8: Seeds *(haiku)*

**Files:**
- Modify: `code/db/seeds.rb`

- [ ] **Step 1: Write seed data**

Replace `code/db/seeds.rb`:

```ruby
member_names = %w[alice bob charlie dana eve frank grace henry iris jake]

members = member_names.map do |name|
  Member.find_or_create_by!(email: "#{name}@example.com") do |m|
    m.display_name = name
    m.password     = "weeb?666"
  end
end

forum_names = %w[ruby rails gamedev linux webdev security learnprogramming devops datascience offbeat]

forum_names.each do |name|
  Forum.find_or_create_by!(name: name) do |f|
    f.created_by_member = members.first
  end
end

puts "Seeded #{Member.count} members and #{Forum.count} forums."
```

- [ ] **Step 2: Run seeds**

```bash
bin/rails db:seed
```

Expected:
```
Seeded 10 members and 10 forums.
```

- [ ] **Step 3: Verify in console**

```bash
bin/rails runner "puts Member.count; puts Forum.count"
```

Expected:
```
10
10
```

- [ ] **Step 4: Commit**

```bash
git add code/db/seeds.rb
git commit -m "Add seed data: 10 members and 10 forums"
```

---

## Self-review

**Spec coverage:**
- ✅ Register — Task 3
- ✅ Login / logout — Task 4
- ✅ Browse forums — Task 6 (index)
- ✅ Create forum — Task 6 (new/create)
- ✅ View forum threads — Task 6 (show)
- ✅ Create thread — Task 7 (forum_posts route)
- ✅ View thread + replies — Task 7 (show)
- ✅ Post reply — Task 7 (post_replies route)
- ✅ Layout nav — Task 5
- ✅ Seeds (10 members, 10 forums, password weeb?666) — Task 8

**Consistency checks:**
- `@post` used for the new-thread form object in both `ForumsController#show` and `PostsController#create_thread` failure path ✅
- `@reply` used for the reply form object in both `PostsController#show` and `create_reply` failure path ✅
- `post_replies_path(@post)` matches route defined in Task 1 ✅
- `forum_posts_path(@forum)` matches route defined in Task 1 ✅
- All scopes (`Forum.active`, `Post.active`, `.replies.active`) match model definitions ✅
