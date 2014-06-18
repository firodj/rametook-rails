class UsersController < ApplicationController
  before_filter :login_required, 
                :only => [:new, :edit, :destroy]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :new, :edit ],
  #        :redirect_to => { :action => :list }
  # verify :method => :delete, :only => [:destroy],
  #        :redirect_to => { :action => :list }
  
  verify  :xhr => true,
          :only => [:filter_cancel, :new_cancel, :show, :close, :destroy],
          :redirect_to => { :action => 'index' }
  verify  :method => :post,
          :only => [:filter],
          :redirect_to => { :action => 'index' }
  
  access_control  :DEFAULT => 'superadmin',
                  :edit => 'superadmin | !superadmin'
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
  ParamToField = 
  { :text => :search_text,
    :department => :department_id }
                   
  hide_action :build_list_options
  # Build +conditions+ from +session filters+
  def build_list_options
    conditions = []
    conditions_str = []
    @search_titles = []
    @search_filters ||= {}
    # convert, from k-params to k-fields
    params_keys = {}
    params.delete_if { |kp,v|
      unless (kf = ParamToField[kp.to_sym]).nil? then
        @search_filters[ kf ] = v
        params_keys[ kf ] = kp
        true
      end
    }

    if @search_filters[:department_id] then        
      filter_instance = Department.find_by_id(@search_filters[:department_id])
      if filter_instance then
        conditions_str << "users.department_id = ?"
        conditions << @search_filters[:department_id]
        @search_titles << ['department', filter_instance]
      end
    end
    if @search_filters[:search_text] then
      search_fields = ['login', 'email', 'crypted_password', 'salt', 'created_at', 'updated_at', 'last_login_at', 'last_ip', 'activation_code', 'activated_at', 'remember_token', 'remember_token_expires_at', 'first_name', 'last_name', 'birthday', 'bio', 'website', 'address', 'city', 'country', 'userimage']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`users`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << "%#{@search_filters[:search_text]}%" }
      end   
      @search_titles << ['text', @search_filters[:search_text]]      
    end
    
    # store again to params (for next link)
    @search_filters.each_pair { |kf,v| params[ params_keys[kf] ] = v }
    
    conditions.unshift( conditions_str.join(' AND ') ) unless conditions.empty?  
  end

  hide_action :build_lookup_belongs
  # Build instance variable from belongs_to
  def build_lookup_belongs(blank = nil)
    # TODO: Remove rescue statement
    @departments = Department.find_all_for_select_option(blank) rescue [['ERROR','']]
    @roles = Role.find_all
  end

  # Default action
  def index
    list
    render :action => 'list'
  end
  
  # List all items
  def list    
    conditions = build_list_options
    paginate_options = {:per_page => 10}
    paginate_options[:conditions] = conditions unless conditions.nil?
    
    @user_pages, @users = paginate :users, paginate_options
  end

  # Show filter's form
  def filter
    build_lookup_belongs('')
    if params[:commit] or params[:clear] then
      params_filter = {:action => 'list'} # add other default filters
      params.each { |kp,v|
        kf = ParamToField[kp.to_sym]
        params_filter[ kp.to_sym ] = v if kf && !v.nil? && !v.empty?
      } if !params[:clear]
      redirect_to params_filter      
    else
      redirect_to :action => 'index' and return unless request.xhr?
      render :update do |page|
        page.hide 'filter_button'
        page['message'].hide
        page.replace_html "message", ''
        page.insert_html :after, "title", :partial => 'filter'
      end
    end
  end
  
  # Close filter's form
  def filter_cancel
    render :update do |page| 
      page.remove 'filter_form'
      page.show 'filter_button'
    end
  end

  # Show New's form, and then Create item
  def new
    @user = User.new(params[:user])
    @user.attributes_from_business_contact(params[:business_contact_id])
    
    # Check if item ready and granted to be created
    if @user.nil? || !granted_to(:create, @user) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    if params[:user]
      @user.roles.clear      
      @user.roles = Role.find_by_id(params[:role_ids]) if params[:role_ids]

      @user.activated_at = Time.now
  
      if @user.save
        
        @user.create_business_contact
        
        # then save uploaded image
        @user.userimage = if params[:user][:userimage].class == StringIO then
          new_image = SHA1.new(Time.now.to_s+params[:user][:userimage].original_filename).to_s
          File.open("#{RAILS_ROOT}/public/images/#{new_image}.jpg", "wb") do |f|  
            f.write(params[:user][:userimage].read)
          end
          "#{new_image}.jpg"
        else
          "admin.gif"
        end
        @user.save
               
        flash[:notice] = print_words('user').capitalize_words + " \"#{@user.display_name}\" " + print_words('has been created')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :action => 'new' # _error,  :layout => 'application'
      end  
    else
    
      # redirect_to :action => 'index' and return unless request.xhr?
      
      if request.xhr? then
      render :update do |page| 
        page.hide 'add_new_button'
        page['message'].hide
        page.replace_html "message", ''
        page.insert_html :after,"title", :partial => 'new'
      end
      end
      
    end    
  end
  
  # Close new's form
  def new_cancel
    render :update do |page| 
      page.remove 'new_form'
      page.show 'add_new_button'
    end
  end 

  # Show Edit's form, and then Update item
  def edit
    current_user
    myaccount = params[:myaccount] || !permit?('superadmin')
    params[:id] = @current_user.id if myaccount

    @user = User.find_by_id(params[:id])
    
    # Check if item found and granted to be updated
    if @user.nil? || !granted_to(:update, @user) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    elem_id = "user_offset_#{@user.id}"
    if params[:user]
      # For admin only
      if permit?('superadmin') then
        @user.roles.clear
        @user.roles << Role.find_by_title('superadmin') if @current_user == @user
        @user.roles += Role.find_by_id(params[:role_ids]) if params[:role_ids]
      else
        # User can't change login & department
        params[:user].delete :login
        params[:user].delete :department_id
      end

      # Handling update or not update password
      if params[:user][:crypted_password].blank?
        params[:user][:crypted_password] = @user.crypted_password
      end
      
      if @user.update_attributes(params[:user].dup.update(:userimage => @user.userimage))
        # Handling user avatar upload
        @user.userimage = 
          if params[:user][:userimage].class == StringIO then
            file_destroy(@user.userimage) unless @user.userimage == 'admin.gif' rescue nil
            new_image = SHA1.new(Time.now.to_s+@user.login).to_s    
            File.open("#{RAILS_ROOT}/public/images/#{new_image}.jpg", "wb") do |f|
              f.write(params[:user][:userimage].read)
            end        
            "#{new_image}.jpg"
          else
            if params[:removeimage].blank?
              @user.userimage
            else
              file_destroy(@user.userimage) unless @user.userimage == 'admin.gif' rescue nil
              'admin.gif'
            end
          end
        @user.save

        flash[:notice] = print_words('user').capitalize_words + " \"#{@user.display_name}\" " + print_words('has been updated')
        
        if myaccount then
          redirect_to :controller => 'account', :action => 'myaccount'
        else
          redirect_to :action => 'list', :page => params[:page]
        end
      else
        if myaccount then
         render :controller => 'account', action => 'myaccount'
        else
          render :action => 'edit' # _error, :layout => 'application'
        end
      end
    else
      redirect_to :action => 'index' and return unless request.xhr?
      render :update do |page| 
        page << %Q{txt = $("#{elem_id}").innerHTML}
        page['message'].hide
        page.replace_html "message", ''
        page.replace_html "user_#{@user.id}", :partial => 'edit'
        page.visual_effect :highlight, "user_#{@user.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
        page << %Q{$("#{elem_id}").update(txt)}
      end
    end
  end

  # Show item
  def show
    @user = User.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @user.nil?
    
    elem_id = "user_offset_#{@user.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "user_#{@user.id}", :partial => 'show'
      page.visual_effect :highlight, "user_#{@user.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @user = User.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @user.nil?
    
    elem_id = "user_offset_#{@user.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "user_#{@user.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "user_#{@user.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @user = User.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @user.nil? || !granted_to(:delete, @user) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    user_display_name = @user.display_name
    if @user.destroy then
      
      file_destroy(@user.userimage) if not @user.userimage.nil? and not @user.userimage == 'admin.gif' rescue nil

      render :update do |page| 
        page.visual_effect :fade, "user_#{@user.id}"
        page.delay 1 do
          page.remove 'user_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('user').capitalize_words + " \"#{user_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "user_#{@user.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
      end
    end
  end
  
  # Item grantted to do
  helper_method :granted_to
  def granted_to(action, item)
    # only registered user can do :create, :update, and :destroy
  	return false unless logged_in?
  	
  	# edit my account
  	return true if action == :update and @current_user == item
  	
  	# only delete item that can be destroyed
  	if action == :delete
  	  return false if @current_user == item
      return false unless item.can_destroyed?
    end
    
    # super admin can do anything
    return true if permit? 'superadmin'
    
    # check item data with @current_user's role, 
    # item may nil if action is :create
    
    # otherwise prevent action
		false
  end   

  # get field name to param key 
  helper_method :field_to_param
  def field_to_param(field_id)
    #@@field_to_param[field_id] 
    ParamToField.index(field_id) || field_id
  end
end
