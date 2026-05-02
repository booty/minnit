class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :display_name, limit: 50, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :access_level, null: false, default: 100
      t.datetime :deleted_at

      t.timestamps
    end

    add_check_constraint :members, "access_level IN (100, 200, 300)", name: "chk_members_access_level"

    add_index :members, "LOWER(display_name)", unique: true, name: "idx_members_lower_display_name"
    add_index :members, "LOWER(email)", unique: true, name: "idx_members_lower_email"
  end
end
