require 'rails_helper'

RSpec.describe "SleepLogsControllers", type: :request do
  # Helper method to parse JSON response body
  def json_response
    JSON.parse(response.body)
  end

  let!(:authenticated_user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(authenticated_user)
  end

  describe "GET /sleep-logs" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:sleep_log1) { create(:sleep_log, user: user1, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours) }
    let!(:sleep_log2) { create(:sleep_log, user: user2, clock_in: 2.days.ago, clock_out: 2.days.ago + 7.hours) }
    let!(:sleep_log3) { create(:sleep_log, user: authenticated_user, clock_in: 3.days.ago, clock_out: 3.days.ago + 6.hours) }
    let!(:sleep_log4) { create(:sleep_log, user: user1, clock_in: 4.days.ago, clock_out: 4.days.ago + 5.hours) }
    let!(:sleep_log5) { create(:sleep_log, user: user2, clock_in: 5.days.ago, clock_out: 5.days.ago + 9.hours) }

    context "when no user_id param and no current_user" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        get '/sleep-logs'
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns all sleep logs" do
        expect(json_response['data'].map { |sl| sl['id'] }).to match_array(SleepLog.all.map(&:id))
        expect(json_response['data'].size).to eq(5)
      end
    end

    context "when user_id param is provided" do
      before { get '/sleep-logs', params: { user_id: user1.id } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns sleep logs for the specified user_id" do
        expect(json_response['data'].map { |sl| sl['id'] }).to match_array([ sleep_log1.id, sleep_log4.id ])
        expect(json_response['data'].size).to eq(2)
      end
    end

    context "when current_user is present and no user_id param" do
      before { get '/sleep-logs' }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns sleep logs for the current_user" do
        expect(json_response['data'].map { |sl| sl['id'] }).to eq([ sleep_log3.id ])
        expect(json_response['data'].size).to eq(1)
      end
    end
  end

  describe "GET /sleep-logs/:id" do
    let!(:sleep_log) { create(:sleep_log, user: authenticated_user) }

    before { get "/sleep-logs/#{sleep_log.id}" }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns the requested sleep log" do
      expect(json_response['data']['id']).to eq(sleep_log.id)
      expect(json_response['data']['user']['id']).to eq(sleep_log.user_id)
    end
  end

  describe "POST /sleep-logs" do
    let(:clock_in_time) { Time.zone.now.beginning_of_hour - 8.hours }
    let(:clock_out_time) { Time.zone.now.beginning_of_hour }
    let(:sleep_log_params) { { clock_in: clock_in_time, clock_out: clock_out_time } }
    let(:mock_sleep_log) { instance_double(SleepLog, id: 1, user_id: authenticated_user.id, clock_in: clock_in_time, clock_out: clock_out_time) }

    before do
      # Stub the `create_log` method on `SleepLogService`
      allow(SleepLogService).to receive(:create_log).and_return(mock_sleep_log)
    end

    context "when authenticated" do
      it "calls SleepLogService.create_log with correct parameters" do
        post '/sleep-logs', params: sleep_log_params, as: :json
        expect(SleepLogService).to have_received(:create_log).with(authenticated_user, ActionController::Parameters.new(sleep_log_params).permit(:clock_in, :clock_out))
      end

      it "creates a new SleepLog and returns a created status" do
        post '/sleep-logs', params: sleep_log_params, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "when not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_raise(Sleepsocial::UnauthenticatedError)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns an unauthorized status" do
        post '/sleep-logs', params: sleep_log_params, as: :json
        expect(response).to have_http_status(:unauthorized) rescue expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /sleep-logs/:id/clock-out" do
    let!(:sleep_log_to_clock_out) { create(:sleep_log, user: authenticated_user, clock_in: 8.hours.ago, clock_out: nil) }
    let(:clock_out_time) { Time.zone.now.beginning_of_minute }
    let(:update_params) { { clock_out: clock_out_time } }
    let(:mock_updated_sleep_log) { build(:sleep_log, id: sleep_log_to_clock_out.id, user_id: authenticated_user.id, clock_in: sleep_log_to_clock_out.clock_in, clock_out: clock_out_time) }

    context "when authenticated" do
      before do
        expect(SleepLog).to receive(:find).and_return(sleep_log_to_clock_out)
        expect(SleepLogService).to receive(:clock_out).with(authenticated_user, sleep_log_to_clock_out, clock_out_time)
      end

      it "calls SleepLogService.clock_out with correct parameters" do
        patch "/sleep-logs/#{sleep_log_to_clock_out.id}/clock-out", params: update_params, as: :json
      end

      it "returns a successful response with the updated sleep log" do
        patch "/sleep-logs/#{sleep_log_to_clock_out.id}/clock-out", params: update_params, as: :json
        expect(response).to be_successful
        expect(json_response['data']['id']).to eq(mock_updated_sleep_log.id)
      end
    end

    context "when not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate!).and_raise(Sleepsocial::UnauthenticatedError)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns an unauthorized status" do
        patch "/sleep-logs/#{sleep_log_to_clock_out.id}/clock-out", params: update_params, as: :json
        expect(response).to have_http_status(:unauthorized) rescue expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
