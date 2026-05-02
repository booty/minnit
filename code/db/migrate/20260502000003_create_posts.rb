class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :member, null: false, foreign_key: { on_delete: :restrict }
      t.references :parent_post, null: true, foreign_key: { to_table: :posts, on_delete: :restrict }
      t.references :forum, null: true, foreign_key: { on_delete: :restrict }
      t.string :title, limit: 200
      t.text :body, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_check_constraint :posts,
      "(forum_id IS NOT NULL AND parent_post_id IS NULL AND title IS NOT NULL) OR " \
      "(forum_id IS NULL AND parent_post_id IS NOT NULL AND title IS NULL)",
      name: "chk_posts_thread_or_reply"
  end
end
