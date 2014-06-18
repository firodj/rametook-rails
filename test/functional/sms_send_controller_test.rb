require File.dirname(__FILE__) + '/../test_helper'
require 'sms_send_controller'

# Re-raise errors caught by the controller.
class SmsSendController; def rescue_action(e) raise e end; end

class SmsSendControllerTest < Test::Unit::TestCase
  def setup
    @controller = SmsSendController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
