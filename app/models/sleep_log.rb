class SleepLog < ApplicationRecord
  include IdentityCache

  belongs_to :user
end
