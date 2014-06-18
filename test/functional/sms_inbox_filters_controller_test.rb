require File.dirname(__FILE__) + '/../test_helper'
require 'sms_inbox_filters_controller'

# Re-raise errors caught by the controller.
class SmsInboxFiltersController; def rescue_action(e) raise e end; end

class SmsInboxFiltersControllerTest < Test::Unit::TestCase
  fixtures :sms_inbox_filters

  def setup
    @controller = SmsInboxFiltersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = sms_inbox_filters(:first).id
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

    assert_not_nil assigns(:sms_inbox_filters)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:sms_inbox_filter)
    assert assigns(:sms_inbox_filter).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:sms_inbox_filter)
  end

  def test_create
    num_sms_inbox_filters = SmsInboxFilter.count

    post :create, :sms_inbox_filter => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_sms_inbox_filters + 1, SmsInboxFilter.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sms_inbox_filter)
    assert assigns(:sms_inbox_filter).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      SmsInboxFilter.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      SmsInboxFilter.find(@first_id)
    }
  end
end
