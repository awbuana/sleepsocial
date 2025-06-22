class SleepLog < ApplicationRecord
  include IdentityCache

  belongs_to :user

  validate :clock_out_gt_clock_in

  def clock_out_gt_clock_in
    if clock_out.present? && clock_out < clock_in
      errors.add(:clock_out, "must be greater than clock in")
    end
  end

  def sleep_duration
    return nil unless clock_out

    (clock_out - clock_in).seconds.in_hours.to_i
  end
end
