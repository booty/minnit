class CreateForums < ActiveRecord::Migration[8.1]
  def change
    create_table :forums do |t|
      t.string :name, limit: 50, null: false
      t.references :created_by_member, null: false, foreign_key: { to_table: :members, on_delete: :restrict }
      t.boolean :nsfw, null: false, default: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :forums, "LOWER(name)", unique: true, name: "idx_forums_lower_name"
  end
end
