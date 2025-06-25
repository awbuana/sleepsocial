require 'rails_helper'

RSpec.describe "LeaderboardsControllers", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  let!(:user_for_timeline) { create(:user, id: 101) }

  describe "GET /leaderboards" do
    let(:user) { create(:user) }
    let(:mock_feed_data) do
      [
        build(:sleep_log, id: 1, user_id: user_for_timeline.id, clock_in: 5.hours.ago, clock_out: 1.hour.ago),
        build(:sleep_log, id: 2, user_id: user.id, clock_in: 10.hours.ago, clock_out: 2.hours.ago)
      ]
    end
    let(:mock_feed_response) do
      {
        data: mock_feed_data,
        offset: 0,
        limit: 2
      }
    end

    before do
      allow(LeaderboardService).to receive(:precomputed_feed).and_return(mock_feed_response)
      allow(User).to receive(:find).and_return(:user_for_timeline)
    end

    context "when a user_id is provided" do
      let(:request_params) { { user_id: user_for_timeline.id, limit: 2, offset: 0 } }

      before { get '/leaderboards', params: request_params, headers: { 'X-USER-ID' => user_for_timeline.id } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "calls LeaderboardService.precomputed_feed with correct parameters" do
        expected_user = User.find(user_for_timeline.id)
        expect(LeaderboardService).to have_received(:precomputed_feed).with(expected_user, limit: "2", offset: "0")
      end

      it "returns the feed data as SleepLogSerializer" do
        expect(json_response['data'].size).to eq(mock_feed_data.size)
        expect(json_response['data'].first['id']).to eq(mock_feed_data.first.id)
        expect(json_response['data'].last['id']).to eq(mock_feed_data.last.id)
      end

      it "returns correct meta information" do
        expect(json_response['meta']['offset']).to eq(mock_feed_response[:offset])
        expect(json_response['meta']['limit']).to eq(mock_feed_response[:limit])
      end
    end

    context "when pagination parameters are omitted" do
      let(:request_params) { { user_id: user_for_timeline.id } }
      let(:mock_feed_response_no_params) do
        {
          data: mock_feed_data,
          offset: 1,
          limit: 2
        }
      end

      before do
        allow(LeaderboardService).to receive(:precomputed_feed).and_return(mock_feed_response_no_params)
        get '/leaderboards', params: request_params, headers: { 'X-USER-ID' => user_for_timeline.id }
      end

      it "calls LeaderboardService.precomputed_feed without limit/offset" do
        expected_user = User.find(user_for_timeline.id)
        expect(LeaderboardService).to have_received(:precomputed_feed).with(expected_user, { limit: nil, offset: nil })
      end

      it "returns feed data and meta with nil offset/limit" do
        expect(json_response['data'].size).to eq(mock_feed_data.size)
        expect(json_response['meta']['offset']).to eq(mock_feed_response_no_params[:offset])
        expect(json_response['meta']['limit']).to eq(mock_feed_response_no_params[:limit])
      end
    end
  end
end
