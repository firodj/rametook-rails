require File.dirname(__FILE__) + '/../test_helper'
require 'sms_inboxes_controller'

# Re-raise errors caught by the controller.
class SmsInboxesController; def rescue_action(e) raise e end; end

class SmsInboxesControllerTest < Test::Unit::TestCase
  fixtures :sms_inboxes

  def setup
    @controller = SmsInboxesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = sms_inboxes(:first).id
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

    assert_not_nil assigns(:sms_inboxes)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:sms_inbox)
    assert assigns(:sms_inbox).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:sms_inbox)
  end

  def test_create
    num_sms_inboxes = SmsInbox.count

    post :create, :sms_inbox => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_sms_inboxes + 1, SmsInbox.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sms_inbox)
    assert assigns(:sms_inbox).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      SmsInbox.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      SmsInbox.find(@first_id)
    }
  end
end
