require File.dirname(__FILE__) + '/../test_helper'
require 'sms_reports_controller'

# Re-raise errors caught by the controller.
class SmsReportsController; def rescue_action(e) raise e end; end

class SmsReportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SmsReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
