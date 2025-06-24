require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'modules' do
    # Test that the modules are included
    it 'includes IdentityCache' do
      expect(User.ancestors).to include(IdentityCache)
    end

    it 'includes UserRelationship' do
      expect(User.ancestors).to include(UserRelationship)
    end
  end

  describe 'associations' do
    it { should have_many(:sleep_logs) }
    it { should have_many(:followers).through(:passive_relationships).source(:user) }
    it { should have_many(:following).through(:active_relationships).source(:target_user) }
  end

  describe 'validations' do
    it 'is valid with a name' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'is invalid without a name' do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:user, name: "Existing User")
      user = User.new(name: "Existing User")
      expect { user.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'default values' do
    it 'sets num_following to 0 by default' do
      user = User.new
      expect(user.num_following).to eq(0)
    end

    it 'sets num_followers to 0 by default' do
      user = User.new
      expect(user.num_followers).to eq(0)
    end

    it 'persists default values on creation' do
      user = create(:user)
      expect(user.reload.num_following).to eq(0)
      expect(user.reload.num_followers).to eq(0)
    end
  end
end
