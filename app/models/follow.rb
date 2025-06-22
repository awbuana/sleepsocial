class Follow < ApplicationRecord
  include IdentityCache

  belongs_to :user
  belongs_to :target_user, class_name: "User"
end
