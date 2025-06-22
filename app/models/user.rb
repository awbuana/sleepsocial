class User < ApplicationRecord
  include IdentityCache
  include UserRelationship
end
