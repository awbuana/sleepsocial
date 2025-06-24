require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:target_user).class_name('User') }
  end

  describe 'validations' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    before do
      # Create an initial follow relationship to test uniqueness against
      create(:follow, user: user_a, target_user: user_b)
    end

    it 'is valid with valid attributes' do
      # A new follow between two different users should be valid
      follow = build(:follow, user: create(:user), target_user: create(:user))
      expect(follow).to be_valid
    end

    it 'is invalid without a user' do
      follow = build(:follow, user: nil)
      expect(follow).not_to be_valid
      expect(follow.errors[:user]).to include('must exist')
    end

    it 'is invalid without a target_user' do
      follow = build(:follow, target_user: nil)
      expect(follow).not_to be_valid
      expect(follow.errors[:target_user]).to include('must exist')
    end

    it 'validates uniqueness of user_id and target_user_id combination' do
      # Attempt to create a duplicate follow relationship
      follow = Follow.new(user: user_a, target_user: user_b)
      expect { follow.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows a user to follow multiple target_users' do
      # user_a already follows user_b. Now let user_a follow user_c.
      user_c = create(:user)
      follow = build(:follow, user: user_a, target_user: user_c)
      expect(follow).to be_valid
    end

    it 'allows multiple users to follow the same target_user' do
      # user_a already follows user_b. Now let user_c follow user_b.
      user_c = create(:user)
      follow = build(:follow, user: user_c, target_user: user_b)
      expect(follow).to be_valid
    end

    it 'prevents a user from following themselves' do
      follow = build(:follow, user: user_a, target_user: user_a)
      expect(follow).not_to be_valid
      expect(follow.errors.first.message).to include('cannot follow yourself')
    end
  end
end
