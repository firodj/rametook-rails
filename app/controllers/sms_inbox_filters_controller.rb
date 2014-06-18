class SmsInboxFiltersController < ApplicationController
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
          :only => [:filter, :new, :edit],
          :redirect_to => { :action => 'index' }
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
  ParamToField =   
  { :text => :search_text,
    :department => :department_id,
    :user => :user_id,
    :group => :user_group_id,
    :addressbook_contact => :addressbook_contact_id }
      
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
        conditions_str << "sms_inbox_filters.department_id = ?"
        conditions << @search_filters[:department_id]
        @search_titles << ['department', filter_instance]
      else
        @search_filters.delete(:department_id)
      end
    end
    if @search_filters[:user_id] then        
      filter_instance = User.find_by_id(@search_filters[:user_id])
      if filter_instance then
        conditions_str << "sms_inbox_filters.user_id = ?"
        conditions << @search_filters[:user_id]
        @search_titles << ['user', filter_instance]
      else
        @search_filters.delete(:user_id)
      end
    end
    if @search_filters[:user_group_id] then        
      filter_instance = Department.find_by_id(@search_filters[:user_group_id])
      if filter_instance then
        conditions_str << "sms_inbox_filters.user_group_id = ?"
        conditions << @search_filters[:user_group_id]
        @search_titles << ['user group', filter_instance]
      else
        @search_filters.delete(:user_group_id)
      end
    end
    if @search_filters[:addressbook_contact_id] then        
      filter_instance = AddressbookContact.find_by_id(@search_filters[:addressbook_contact_id])
      if filter_instance then
        conditions_str << "sms_inbox_filters.addressbook_contact_id = ?"
        conditions << @search_filters[:addressbook_contact_id]
        @search_titles << ['addressbook contact', filter_instance]
      else
        @search_filters.delete(:addressbook_contact_id)
      end
    end
    if @search_filters[:search_text] then
      search_fields = []
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`sms_inbox_filters`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << "%#{@search_filters[:search_text]}%" }
      end   
      @search_titles << ['text', @search_filters[:search_text]]      
    end
    
    # store again to params (for next link)
    @search_filters.each_pair { |kf,v| params[ params_keys[kf] ] = v }
    
    # return conditions array
    conditions.unshift( conditions_str.join(' AND ') ) unless conditions_str.empty?
    conditions unless conditions.empty?
  end

  hide_action :build_lookup_belongs
  # Build instance variable from belongs_to
  def build_lookup_belongs(blank = nil)
    # TODO: Remove rescue statement
    @departments = Department.find_all_for_select_option('') rescue [['ERROR','']]
    @users = User.find_all_for_select_option('') rescue [['ERROR','']]
    @groups = Department.find_all_for_select_option('') rescue [['ERROR','']]
    @addressbook_contacts = AddressbookContact.find_all_for_select_option('') rescue [['ERROR','']]
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
    
    @sms_inbox_filter_pages, @sms_inbox_filters = paginate :sms_inbox_filters, paginate_options
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
    @sms_inbox_filter = SmsInboxFilter.new(params[:sms_inbox_filter])
    
    # Check if item ready and granted to be created
    if @sms_inbox_filter.nil? || !granted_to(:create, @sms_inbox_filter) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    if params[:sms_inbox_filter]
      #uploadfile = params[:sms_inbox_filter].delete(:uploadfile)
      if @sms_inbox_filter.save
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ##
        #@sms_inbox_filter.uploadfile = if uploadfile.respond_to?(:original_filename) then
        #  prefix = "#{@sms_inbox_filter.id}_" # SHA1.new(Time.now.to_s).to_s
        #  new_uploadfile = prefix + uploadfile.original_filename
        #  File.open("#{RAILS_ROOT}/public/files/#{new_uploadfile}", "wb") do |f|  
        #    f.write(uploadfile.read)
        #  end
        #  new_uploadfile
        #else
        #  nil # default value
        #end
        #@sms_inbox_filter.save # save again

        flash[:notice] = print_words('sms inbox filter').capitalize_words + " \"#{@sms_inbox_filter.display_name}\" " + print_words('has been created')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :partial => 'new_error', :layout => 'application'
      end  
    else
      redirect_to :action => 'index' and return unless request.xhr?
      render :update do |page| 
        page.hide 'add_new_button'
        page['message'].hide
        page.replace_html "message", ''
        page.insert_html :after,"title", :partial => 'new'
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
    @sms_inbox_filter = SmsInboxFilter.find_by_id(params[:id])
    # Get the uploaded file data first !
    #uploadfile = params[:sms_inbox_filter].delete(:uploadfile) if params[:sms_inbox_filter]
    @sms_inbox_filter.attributes = params[:sms_inbox_filter]
      
    # Check if item found and granted to be updated
    if @sms_inbox_filter.nil? || !granted_to(:update, @sms_inbox_filter) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    elem_id = "sms_inbox_filter_offset_#{@sms_inbox_filter.id}"
    if params[:sms_inbox_filter]
      ## It's to help if you need to upload file/images, DB field name: image
      ## Check the form field and don't forget to set the multipart=true 
      ##
      if @sms_inbox_filter.save
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ## And add an check box button to delete file, name: removefile
        ##
        #@sms_inbox_filter.uploadfile = 
        #  if uploadfile.respond_to?(:original_filename) then
        #    file_destroy(@sms_inbox_filter.uploadfile) unless @sms_inbox_filter.uploadfile.nil? rescue nil # delete if not default value
        #    prefix = "#{@sms_inbox_filter.id}_" # SHA1.new(Time.now.to_s).to_s
        #    new_uploadfile = prefix + uploadfile.original_filename
        #    File.open("#{RAILS_ROOT}/public/files/#{new_uploadfile}", "wb") do |f|
        #      f.write(uploadfile.read)
        #    end        
        #    new_uploadfile
        #  else
        #    if params[:removefile].blank?
        #      @sms_inbox_filter.uploadfile # no change
        #    else 
        #      file_destroy(@sms_inbox_filter.uploadfile) unless @sms_inbox_filter.uploadfile.nil? rescue nil # delete if not default value
        #      nil # default value
        #    end
        #  end
        #@sms_inbox_filter.save #save again

        flash[:notice] = print_words('sms inbox filter').capitalize_words + " \"#{@sms_inbox_filter.display_name}\" " + print_words('has been updated')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :partial => 'edit_error', :layout => 'application'
      end
    else
      redirect_to :action => 'index' and return unless request.xhr?
      render :update do |page| 
        page << %Q{txt = $("#{elem_id}").innerHTML}
        page['message'].hide
        page.replace_html "message", ''
        page.replace_html "sms_inbox_filter_#{@sms_inbox_filter.id}", :partial => 'edit'
        page.visual_effect :highlight, "sms_inbox_filter_#{@sms_inbox_filter.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
        page << %Q{$("#{elem_id}").update(txt)}
      end
    end
  end

  # Show item
  def show
    @sms_inbox_filter = SmsInboxFilter.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @sms_inbox_filter.nil?
    
    elem_id = "sms_inbox_filter_offset_#{@sms_inbox_filter.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "sms_inbox_filter_#{@sms_inbox_filter.id}", :partial => 'show'
      page.visual_effect :highlight, "sms_inbox_filter_#{@sms_inbox_filter.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @sms_inbox_filter = SmsInboxFilter.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @sms_inbox_filter.nil?
    
    elem_id = "sms_inbox_filter_offset_#{@sms_inbox_filter.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "sms_inbox_filter_#{@sms_inbox_filter.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "sms_inbox_filter_#{@sms_inbox_filter.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @sms_inbox_filter = SmsInboxFilter.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @sms_inbox_filter.nil? || !granted_to(:delete, @sms_inbox_filter) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    sms_inbox_filter_display_name = @sms_inbox_filter.display_name
    if @sms_inbox_filter.destroy then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      #file_destroy(@sms_inbox_filter.uploadfile) unless @sms_inbox_filter.uploadfile.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "sms_inbox_filter_#{@sms_inbox_filter.id}"
        page.delay 1 do
          page.remove 'sms_inbox_filter_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('sms inbox filter').capitalize_words + " \"#{sms_inbox_filter_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "sms_inbox_filter_#{@sms_inbox_filter.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
      end
    end
  end
  
  # Item grantted to do
  helper_method :granted_to
  def granted_to(action, item)
    # only registered user can do :create, :update, and :delete
  	return false unless logged_in?
  	
  	# only delete item that can be destroyed
    return false if action == :delete and not item.can_destroyed?
    
    # check also update here!
    
    # super admin can do anything
    return true if permit? 'superadmin'
    
    # check item data with @current_user's role, 
    # item may nil if action is :create
    return true if action == :create
    
    # otherwise prevent action
		false
  end
  
  # get field name to param key 
  helper_method :field_to_param
  def field_to_param(field_id)
    ParamToField.index(field_id) || field_id
  end
end
