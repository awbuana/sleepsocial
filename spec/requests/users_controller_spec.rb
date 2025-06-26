require 'rails_helper'

RSpec.describe "UsersControllers", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  describe "GET /users" do
    let!(:user1) { create(:user, name: "Alice") }
    let!(:user2) { create(:user, name: "Bob") }
    let!(:user3) { create(:user, name: "Charlie") }
    let!(:user4) { create(:user, name: "David") }
    let!(:user5) { create(:user, name: "Eve") }

    context "without pagination parameters" do
      before { get '/users' }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns all users" do
        expect(json_response['data'].map { |u| u['id'] }).to match_array(User.all.order(id: :asc).map(&:id))
        expect(json_response['data'].size).to eq(5)
      end
    end

    context "with limit parameter" do
      before { get '/users', params: { limit: 2 } }

      it "returns a limited number of users" do
        expect(json_response['data'].size).to eq(2)
      end

      it "returns next_cursor for pagination" do
        expect(json_response['meta']['next_cursor']).not_to be_nil
      end
    end
  end

  describe "GET /users/:id" do
    let!(:user) { create(:user) }

    context "user exists" do
      before { get "/users/#{user.id}" }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns the requested user" do
        expect(json_response['data']['id']).to eq(user.id)
        expect(json_response['data']['name']).to eq(user.name)
      end
    end

    context "user doesn't exist" do
      before do
        allow(User).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        get "/users/#{user.id}"
      end

      it "returns 404" do
        expect(response.status).to be(404)
      end
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:user_params) { { user: { name: "New User" } } }

      it "creates a new User" do
        expect {
          post '/users', params: user_params, as: :json
        }.to change(User, :count).by(1)
      end

      it "returns a created status" do
        post '/users', params: user_params, as: :json
        expect(response).to have_http_status(:created)
      end

      it "returns the created user" do
        post '/users', params: user_params, as: :json
        expect(json_response['data']['name']).to eq("New User")
        expect(json_response['data']['id']).not_to be_nil
      end
    end

    context "with invalid parameters" do
      let(:user_params) { { user: { name: nil } } } # Assuming name is required

      it "does not create a new User" do
        expect {
          post '/users', params: user_params, as: :json
        }.to_not change(User, :count)
      end

      it "returns an unprocessable entity status" do
        post '/users', params: user_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages" do
        post '/users', params: user_params, as: :json
        expect(json_response).to have_key('error')
      end
    end

    context "user permission denied" do
      let(:user_params) { { user: { name: 'bob' } } }

      before do
        allow_any_instance_of(User).to receive(:save!).and_raise(Sleepsocial::PermissionDeniedError)
        post '/users', params: user_params, as: :json
      end

      it "returns 403" do
        expect(response.status).to be(403)
      end
    end

    context "duplicate users" do
      let(:user_params) { { user: { name: 'bob' } } }

      before do
        allow_any_instance_of(User).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
        post '/users', params: user_params, as: :json
      end

      it "returns 422" do
        expect(response.status).to be(422)
        expect(json_response['error']).to eq("Duplicate record")
      end
    end
  end

  describe "GET /users/:id/following" do
    let!(:user1) { create(:user) }
    let!(:followed_user_1) { create(:user) }
    let!(:followed_user_2) { create(:user) }
    let!(:follow_record_1) { create(:follow, user: user1, target_user: followed_user_1) }
    let!(:follow_record_2) { create(:follow, user: user1, target_user: followed_user_2) }

    context "when the user has followings" do
      before do
        get following_user_path(user1)
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns a list of users the user is following" do
        expect(json_response['data'].count).to eq(2)
        expect(json_response['data'].first['id']).to eq(follow_record_1.id)
        expect(json_response['data'].second['id']).to eq(follow_record_2.id)
      end

      it "returns pagination metadata" do
        expect(json_response['meta']['prev_cursor']).not_to be_nil
        expect(json_response['meta']['next_cursor']).not_to be_nil
      end
    end

    context "when the user has no followings" do
      let!(:user_no_following) { create(:user) } # A user with no followings

      before do
        get following_user_path(user_no_following)
      end

      it "returns an empty list" do
        expect(json_response['data']).to be_empty
      end

      it "returns nil for pagination cursors" do
        expect(json_response['meta']['prev_cursor']).to be_nil
        expect(json_response['meta']['next_cursor']).to be_nil
      end
    end
  end

  describe "GET /users/:id/followers" do
    let!(:user1) { create(:user) }
    let!(:follower_user_1) { create(:user) }
    let!(:follower_user_2) { create(:user) }
    let!(:follow_record_1) { create(:follow, user: follower_user_1, target_user: user1) }
    let!(:follow_record_2) { create(:follow, user: follower_user_2, target_user: user1) }

    context "when the user has followers" do
      before do
        get followers_user_path(user1)
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns a list of users who are following the user" do
        expect(json_response['data'].count).to eq(2)
        expect(json_response['data'].first['id']).to eq(follow_record_1.id)
        expect(json_response['data'].second['id']).to eq(follow_record_2.id)
      end

      it "returns pagination metadata" do
        expect(json_response['meta']['prev_cursor']).not_to be_nil
        expect(json_response['meta']['next_cursor']).not_to be_nil
      end
    end

    context "when the user has no followers" do
      let!(:user_no_followers) { create(:user) } # A user with no followers

      before do
        get followers_user_path(user_no_followers)
      end

      it "returns an empty list" do
        expect(json_response['data']).to be_empty
      end

      it "returns nil for pagination cursors" do
        expect(json_response['meta']['prev_cursor']).to be_nil
        expect(json_response['meta']['next_cursor']).to be_nil
      end
    end
  end
end
