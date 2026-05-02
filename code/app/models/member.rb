class Member < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy
  has_many :created_forums, class_name: "Forum", foreign_key: :created_by_member_id, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }

  validates :display_name, presence: true, length: { maximum: 50 },
                            uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :access_level, inclusion: { in: [ 100, 200, 300 ] }
end
