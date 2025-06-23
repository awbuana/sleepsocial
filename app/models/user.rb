class User < ApplicationRecord
  include IdentityCache
  include UserRelationship

  has_many :sleep_logs
end
