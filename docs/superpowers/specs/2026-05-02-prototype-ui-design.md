# Prototype UI — Design Spec

**Date:** 2026-05-02
**Scope:** Controllers, views, routes, auth, and seed data for a working Rails prototype. Bare HTML only; no CSS framework yet.

---

## Goals

A logged-in member can:
- Register an account
- Log in / log out
- Browse all forums
- Create a new forum
- View a forum's threads
- Create a thread in a forum
- View a thread's replies
- Post a reply to a thread

Replies to replies are out of scope for this slice.

---

## Routes

```
root → forums#index

GET    /signup                      registrations#new
POST   /signup                      registrations#create
GET    /login                       sessions#new
POST   /login                       sessions#create
DELETE /logout                      sessions#destroy

GET    /forums                      forums#index
GET    /forums/new                  forums#new
POST   /forums                      forums#create
GET    /forums/:id                  forums#show

POST   /forums/:forum_id/posts      posts#create   # creates thread
GET    /posts/:id                   posts#show     # thread + replies
POST   /posts/:post_id/replies      posts#create   # creates reply
```

---

## Controllers

### ApplicationController
- `current_member` — memoized from `session[:member_id]`; returns `nil` when logged out
- `require_login` — redirects to `/login` with flash notice when `current_member` is nil
- `helper_method :current_member`

### RegistrationsController
- `new` — renders signup form
- `create` — creates `Member`, logs them in via `session[:member_id]`, redirects to root

### SessionsController
- `new` — renders login form
- `create` — authenticates with `has_secure_password`'s `authenticate`, sets `session[:member_id]`, redirects to root
- `destroy` — clears session, redirects to root

### ForumsController
- `index` — `Forum.active.order(:name)` with thread count
- `show` — loads forum + top-level threads (`Post.active.where(forum: @forum).order(created_at: :desc)`)
- `new` — blank forum form; requires login
- `create` — creates forum with `created_by_member: current_member`; requires login

### PostsController
- `show` — loads post + direct replies (`Post.active.where(parent_post: @post).order(created_at: :asc)`)
- `create` — handles both threads and replies based on which route param is present:
  - `params[:forum_id]` present → thread (`forum_id`, `title`, `body`)
  - `params[:post_id]` present → reply (`parent_post_id`, `body`; title omitted)
  - Requires login for both

---

## Views

### Layout (`layouts/application.html.erb`)
Nav bar with: site name (links to root), "Forums" link, and either login/signup links or the current member's display_name + logout button. Flash region below nav.

### `forums/index`
Table: forum name (link to show), post count, created by. "New Forum" link at top (visible to logged-in members).

### `forums/show`
Forum name + NSFW badge if applicable. List of threads (title, author, reply count, posted at). "New Thread" form inline at the bottom (visible to logged-in members; link to login otherwise).

### `forums/new`
Form: name, NSFW checkbox. Submit creates forum.

### `posts/show`
Thread title, body, author, posted at. Flat list of replies below (body, author, posted at). Reply form at the bottom (visible to logged-in members; link to login otherwise).

### `registrations/new`
Form: display_name, email, password. On error, re-renders with `@member.errors`.

### `sessions/new`
Form: email, password. On failure, re-renders with a flash alert.

---

## Auth

- `session[:member_id]` set on login, cleared on logout
- `current_member` returns `Member.find_by(id: session[:member_id])` (find_by to avoid raising on stale sessions)
- Protected actions: `ForumsController#new/create`, `PostsController#create`
- Unauthenticated access to protected actions redirects to `/login` with `flash[:notice]`

---

## Seeds

10 members with `display_name`, `email`, `password: "weeb?666"`.

10 forums:
`ruby`, `rails`, `gamedev`, `linux`, `webdev`, `security`, `learnprogramming`, `devops`, `datascience`, `offbeat`

All forums created by the first seeded member (`seed_user_1`).
