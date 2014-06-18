class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem

  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie

  # Filtering for restriction access
  before_filter :login_required, :only => [ :admin_home, :myaccount ]

  def index
    # language_info (put this on the 1st page loaded)
    # NOTE: also set session[:language] if our app had switch language module
    # NOTE: also flush or session's language words when language switched
    #session[:language] = setting_info('language')
      
    #redirect_to(:action => 'signup') unless logged_in? || User.count > 0
    redirect_to(:action => 'admin_home')
  end

  def login
    redirect_to :action => 'index' and return if logged_in?
    return unless request.post?

    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == '1'
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      User.update(current_user.id, {:last_login_at => Time.now, :last_ip => request.remote_ip})
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = print_words('login successful').capitalize
    end
  end

  def signup
    redirect_to :action => 'index' and return if Setting.find_by_name('open signup').value != 'yes'
    @user = User.new(params[:user])
    @user.last_login_at, @user.last_ip = Time.now, request.remote_ip
    @user.department_id = 1
    return unless request.post?
    if @user.save
      # Send email
      @from = Setting.find_by_name('site email').value
      @subject = Setting.find_by_name('site name').value
      @host = Setting.find_by_name('site host').value
      Notifier.deliver_signup_thanks(@user, @from, @subject, @host)
      
      flash[:notice] = print_words('registration success').capitalize
      redirect_to :action => 'login'
    else
      render :action => 'signup'
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    #session[:language] = Setting.find_by_name('language').value
    flash[:notice] = print_words('logout').capitalize
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  def activate
    #session[:language] = setting_info('language')
    if params[:activation_code] || params[:id]
      @user = User.find_by_activation_code(params[:id]) if params[:id]
      @user = User.find_by_activation_code(params[:activation_code]) if params[:activation_code]
      if @user and @user.activate
        self.current_user = @user
        redirect_back_or_default(:controller => '/account', :action => 'index')
        flash[:notice] = print_words('welcome').capitalize
      else
        flash[:notice] = print_words('are you sure').capitalize
      end
    else
      flash.clear
    end
  end

  # My Account, edit current user preferences
  def myaccount
    params[:id] = current_user.id
    @departments = Department.find_all_for_select_option
    @roles = Role.find_all
    @user = User.find(params[:id])
  end
      
end
