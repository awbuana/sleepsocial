class SleepLog < ApplicationRecord
  include IdentityCache

  belongs_to :user

  validate :clock_out_gt_clock_in, :clock_in_lt_now

  def clock_out_gt_clock_in
    if clock_out.present? && clock_out < clock_in
      errors.add(:clock_out, "must be greater than clock in")
    end
  end

  def clock_in_lt_now
    # add buffer
    if clock_in > Time.now.utc + 15.seconds
      errors.add(:clock_in, "must be lower than now")
    end
  end
end
