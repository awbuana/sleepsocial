class SleepLog < ApplicationRecord
  include IdentityCache

  belongs_to :user

  validate :clock_out_gt_clock_in

  def clock_out_gt_clock_in
    if clock_out.present? && clock_out < clock_in
      errors.add(:clock_out, "must be greater than clock in")
    end
  end
end
