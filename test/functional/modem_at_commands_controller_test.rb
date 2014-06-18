require File.dirname(__FILE__) + '/../test_helper'
require 'modem_at_commands_controller'

# Re-raise errors caught by the controller.
class ModemAtCommandsController; def rescue_action(e) raise e end; end

class ModemAtCommandsControllerTest < Test::Unit::TestCase
  fixtures :modem_at_commands

  def setup
    @controller = ModemAtCommandsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = modem_at_commands(:first).id
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

    assert_not_nil assigns(:modem_at_commands)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:modem_at_command)
    assert assigns(:modem_at_command).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:modem_at_command)
  end

  def test_create
    num_modem_at_commands = ModemAtCommand.count

    post :create, :modem_at_command => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_modem_at_commands + 1, ModemAtCommand.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:modem_at_command)
    assert assigns(:modem_at_command).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      ModemAtCommand.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ModemAtCommand.find(@first_id)
    }
  end
end
