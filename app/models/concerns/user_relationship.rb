# frozen_string_literal: true

module UserRelationship
  extend ActiveSupport::Concern

  included do
    has_many :active_relationships, class_name: "Follow", foreign_key: "user_id", inverse_of: :user
    has_many :passive_relationships, class_name: "Follow", foreign_key: "target_user_id", inverse_of: :target_user_id
    has_many :following, -> { order(follows: { id: :desc }) }, through: :active_relationships,  source: :target_user
    has_many :followers, -> { order(follows: { id: :desc }) }, through: :passive_relationships, source: :user
  end
end
