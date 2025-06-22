require "test_helper"

class SleepLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sleep_log = sleep_logs(:one)
  end

  test "should get index" do
    get sleep_logs_url, as: :json
    assert_response :success
  end

  test "should create sleep_log" do
    assert_difference("SleepLog.count") do
      post sleep_logs_url, params: { sleep_log: { user_id: @sleep_log.user_id } }, as: :json
    end

    assert_response :created
  end

  test "should show sleep_log" do
    get sleep_log_url(@sleep_log), as: :json
    assert_response :success
  end

  test "should update sleep_log" do
    patch sleep_log_url(@sleep_log), params: { sleep_log: { user_id: @sleep_log.user_id } }, as: :json
    assert_response :success
  end

  test "should destroy sleep_log" do
    assert_difference("SleepLog.count", -1) do
      delete sleep_log_url(@sleep_log), as: :json
    end

    assert_response :no_content
  end
end
