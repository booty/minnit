class Forum < ApplicationRecord
  belongs_to :created_by_member, class_name: "Member"

  has_many :posts, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }

  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { case_sensitive: false }
end
