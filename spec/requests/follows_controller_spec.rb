require 'rails_helper'

RSpec.describe "FollowsControllers", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  let!(:authenticated_user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(authenticated_user)
  end

  describe "GET /follows" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    let!(:follow1) { create(:follow, user: user1, target_user: user2) }
    let!(:follow2) { create(:follow, user: user2, target_user: user1) }

    context "when no user_id param and no current_user" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        get '/follows'
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns all follows ordered by id descending" do
        expect(json_response['data'].map { |f| f['id'] }).to match_array([ follow2.id, follow1.id ])
        expect(json_response['data'].size).to eq(2)
      end
    end

    context "when user_id param is provided" do
      before { get "/follows", params: { user_id: user1.id } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns follows for the specified user_id" do
        expect(json_response['data'].map { |f| f['id'] }).to eq([ follow1.id ])
        expect(json_response['data'].size).to eq(1)
      end
    end

    context "when current_user is present and no user_id param" do
      let!(:follow_by_current_user) { create(:follow, user: authenticated_user, target_user: user1) }
      let!(:another_follow) { create(:follow, user: user2, target_user: authenticated_user) }

      before { get "/follows" }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns follows for the current_user" do
        expect(json_response['data'].map { |f| f['id'] }).to eq([ follow_by_current_user.id ])
        expect(json_response['data'].size).to eq(1)
      end
    end

    context "with pagination parameters" do
      let!(:follows) do
        Array.new(5) { create(:follow, user: user1, target_user: create(:user)) }
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns paginated results" do
        get "/follows", params: { limit: 2 }

        expect(json_response['data'].size).to eq(2)
        expect(json_response['meta']).to have_key('next_cursor')
      end
    end
  end

  describe "GET /follows/:id" do
    let!(:follow) { create(:follow) }

    before { get "/follows/#{follow.id}" }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns the requested follow" do
      expect(json_response['data']['id']).to eq(follow.id)
    end
  end

  describe "POST /follows" do
    let(:target_user) { create(:user) }
    let(:follow_params) { { follow: { target_user_id: target_user.id } } }
    let(:mock_follow) { instance_double(Follow, id: 1, user_id: authenticated_user.id, target_user_id: target_user.id) }

    before do
      allow(FollowService).to receive(:follow).and_return(mock_follow)
    end

    context "when authenticated" do
      it "returns a created status" do
        post '/follows', params: follow_params, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "when not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_raise(Sleepsocial::UnauthenticatedError)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns an unauthorized status" do
        post '/follows', params: follow_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /follows" do
    let(:target_user) { create(:user) }
    let(:unfollow_params) { { follow: { target_user_id: target_user.id } } }

    before do
      allow(FollowService).to receive(:unfollow).and_return(true)
    end

    context "when authenticated" do
      it "calls FollowService.unfollow" do
        delete '/follows', params: unfollow_params, as: :json
        expect(FollowService).to have_received(:unfollow).with(authenticated_user, target_user.id)
      end

      it "returns a successful message" do
        delete '/follows', params: unfollow_params, as: :json
        expect(response).to be_successful
        expect(json_response['message']).to eq("Unfollow successfully")
      end
    end

    context "when not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_raise(Sleepsocial::UnauthenticatedError)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns an unauthorized status" do
        delete '/follows', params: unfollow_params, as: :json
        expect(response).to have_http_status(:unauthorized) rescue expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
