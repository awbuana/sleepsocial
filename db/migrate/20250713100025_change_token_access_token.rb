# frozen_string_literal: true

class ChangeTokenAccessToken < ActiveRecord::Migration[8.0]
  def self.up
    remove_index :oauth_access_tokens, name: :index_oauth_access_tokens_on_token
    change_table :oauth_access_tokens do |t|
      t.change :token, :text
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
