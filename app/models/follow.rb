class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :target_user, class_name: "User"

  validate :cannot_follow_self

  def self.use_index(index)
    from("#{self.table_name} USE INDEX(#{index})")
  end

  private

  def cannot_follow_self
    if user_id == target_user_id
      errors.add(:target_user_id, "cannot follow yourself")
    end
  end
end
