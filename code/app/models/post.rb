class Post < ApplicationRecord
  belongs_to :member
  belongs_to :forum, optional: true
  belongs_to :parent_post, class_name: "Post", optional: true

  has_many :replies, class_name: "Post", foreign_key: :parent_post_id, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }

  validates :body, presence: true
  validate :thread_or_reply_structure

  private

  def thread_or_reply_structure
    if forum_id.present? && parent_post_id.present?
      errors.add(:base, "cannot belong to both a forum and a parent post")
    elsif forum_id.present?
      errors.add(:title, "can't be blank") if title.blank?
    elsif parent_post_id.present?
      errors.add(:title, "must be blank for replies") if title.present?
    else
      errors.add(:base, "must belong to a forum or a parent post")
    end
  end
end
