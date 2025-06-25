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

    before { get "/users/#{user.id}" }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns the requested user" do
      expect(json_response['data']['id']).to eq(user.id)
      expect(json_response['data']['name']).to eq(user.name)
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
  end
end
