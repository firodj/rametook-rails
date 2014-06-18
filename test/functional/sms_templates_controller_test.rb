require File.dirname(__FILE__) + '/../test_helper'
require 'sms_templates_controller'

# Re-raise errors caught by the controller.
class SmsTemplatesController; def rescue_action(e) raise e end; end

class SmsTemplatesControllerTest < Test::Unit::TestCase
  fixtures :sms_templates

  def setup
    @controller = SmsTemplatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = sms_templates(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:sms_templates)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:sms_template)
    assert assigns(:sms_template).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:sms_template)
  end

  def test_create
    num_sms_templates = SmsTemplate.count

    post :create, :sms_template => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_sms_templates + 1, SmsTemplate.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sms_template)
    assert assigns(:sms_template).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      SmsTemplate.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      SmsTemplate.find(@first_id)
    }
  end
end
