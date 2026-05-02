# Overview

This app is a Rails 8 "Solid Stack" app similar to Reddit. This is a toy/learning app, not meant for public production deployment.

For this slice, create the data models ONLY.

Users are called `members`.

Forums are called `forums`, not `subreddits`.

There is no separate `threads` table. A thread is represented by a top-level `post`.

Do not implement moderation, voting, subscriptions, search, notifications, or ranking in this iteration.

## Functionality

Data models should support:

- Members can log in
- Members can create a new forum
- Members can create a new thread in an existing forum
- Members can reply to an existing thread or to another reply

## General Rules

All models have:

- `id` autoincrement primary key
- `created_at`
- `updated_at`
- `deleted_at` nullable timestamp for soft deletes

Columns are non-nullable unless explicitly marked nullable.

All foreign keys should:

- be indexed
- use database-level foreign key constraints
- use `ON DELETE RESTRICT` unless otherwise stated

Soft-deleted rows are retained. Normal application queries should exclude rows where `deleted_at IS NOT NULL`.

## Models

### `members`

Represents a logged-in user.

Columns:

- `display_name` varchar(50)
- `email` varchar
- `password_digest` varchar
- `access_level` integer, default `100`

Access levels:

- `100` = member
- `200` = moderator
- `300` = sysadmin

Constraints:

- `display_name` required
- `email` required
- `password_digest` required
- `access_level IN (100, 200, 300)`

Indexes:

- unique case-insensitive index on `display_name`
- unique case-insensitive index on `email`

### `forums`

Represents a forum.

Columns:

- `name` varchar(50)
- `created_by_member_id` FK to `members`
- `nsfw` boolean, default `false`

Constraints:

- `name` required
- `created_by_member_id` required

Indexes:

- unique case-insensitive index on `name`
- index on `created_by_member_id`

### `posts`

Represents both top-level threads and replies.

A top-level thread is a `post` with `forum_id` present and `parent_post_id` null.

A reply is a `post` with `parent_post_id` present and `forum_id` null.

Columns:

- `member_id` FK to `members`
- `parent_post_id` FK to `posts`, nullable
- `forum_id` FK to `forums`, nullable
- `title` varchar(200), nullable
- `body` text

Constraints:

- `member_id` required
- `body` required
- exactly one of `forum_id` or `parent_post_id` must be present
- if `forum_id` is present:
  - post is a top-level thread
  - `title` is required
- if `parent_post_id` is present:
  - post is a reply
  - `title` must be null

Indexes:

- index on `member_id`
- index on `forum_id`
- index on `parent_post_id`

Recommended DB check constraints:

```sql
(
  forum_id IS NOT NULL
  AND parent_post_id IS NULL
  AND title IS NOT NULL
)
OR
(
  forum_id IS NULL
  AND parent_post_id IS NOT NULL
  AND title IS NULL
)
```

## Rails Naming

Use these association names:

- Member
  - has_many :posts
  - has_many :created_forums, class_name: "Forum"
- Forum
  - belongs_to :created_by_member, class_name: "Member"
  - has_many :posts
- Post
  - belongs_to :member
  - belongs_to :forum, optional: true
  - belongs_to :parent_post, class_name: "Post", optional: true
  - has_many :replies, class_name: "Post", foreign_key: :parent_post_id -

## Notes

Avoid adding model behavior beyond validations and associations in this slice.

Do not add service objects, query objects, policies, moderation models, voting models, or UI/controller behavior yet.
