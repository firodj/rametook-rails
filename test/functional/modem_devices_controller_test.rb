require File.dirname(__FILE__) + '/../test_helper'
require 'modem_devices_controller'

# Re-raise errors caught by the controller.
class ModemDevicesController; def rescue_action(e) raise e end; end

class ModemDevicesControllerTest < Test::Unit::TestCase
  fixtures :modem_devices

  def setup
    @controller = ModemDevicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = modem_devices(:first).id
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

    assert_not_nil assigns(:modem_devices)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:modem_device)
    assert assigns(:modem_device).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:modem_device)
  end

  def test_create
    num_modem_devices = ModemDevice.count

    post :create, :modem_device => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_modem_devices + 1, ModemDevice.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:modem_device)
    assert assigns(:modem_device).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      ModemDevice.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ModemDevice.find(@first_id)
    }
  end
end
