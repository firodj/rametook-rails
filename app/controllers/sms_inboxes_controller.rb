class SmsInboxesController < ApplicationController
  before_filter :login_required
               # :only => [:new, :edit, :destroy,]
  access_control :DEFAULT => 'superadmin | inboxadmin'
  
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
  { :text => :search_text }
      
  hide_action :build_list_options
  # Build +conditions+ from +session filters+
  def build_list_options(options = {})
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

    #if options[:user] then
    #  conditions_str << '(user_id = ? OR user_group_id = ?)'
    #  conditions     << options[:user].id
    #  conditions     << options[:user].department_id
    #end
    
    if @search_filters[:search_text] then
      search_fields = ['number', 'message', 'has_read']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`sms_inboxes`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << "%#{@search_filters[:search_text]}%" }
      end   
      @search_titles << ['text', @search_filters[:search_text]]      
    end
    
    # don't include removed
    conditions_str << 'removed = ?'
    conditions     << false
    
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
  end

  # Default action
  def index
    list
    render :action => 'list'
  end
  
  # List all items
  def list    
    conditions = build_list_options(:user => self.current_user)
    paginate_options = {:per_page => 10}
    paginate_options[:conditions] = conditions unless conditions.nil?
    paginate_options[:order] = 'received_time DESC, sent_time DESC'
    @sms_inbox_pages, @sms_inboxes = paginate :sms_inboxes, paginate_options
  end
=begin
  def list_for_admin    
    conditions = build_list_options(:admin => true)
    paginate_options = {:per_page => 20}
    paginate_options[:conditions] = conditions unless conditions.nil?
    paginate_options[:order] = 'received_time DESC, sent_time DESC'
    @sms_inbox_pages, @sms_inboxes = paginate :sms_inboxes, paginate_options
    render :action => 'list'
  end
=end

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
    @sms_inbox = SmsInbox.new( params[:sms_inbox] )
    
    # Check if item ready and granted to be created
    if @sms_inbox.nil? || !granted_to(:create, @sms_inbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    if params[:sms_inbox]
      if @sms_inbox.save
        flash[:notice] = print_words('sms inbox').capitalize_words + " \"#{@sms_inbox.display_name}\" " + print_words('has been created')
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
    @sms_inbox = SmsInbox.find_by_id(params[:id])
    
    # Check if item found and granted to be updated
    if @sms_inbox.nil? || !granted_to(:update, @sms_inbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    elem_id = "sms_inbox_offset_#{@sms_inbox.id}"
    if params[:sms_inbox]
      if @sms_inbox.update_attributes(params[:sms_inbox])
        flash[:notice] = print_words('sms inbox').capitalize_words + " \"#{@sms_inbox.display_name}\" " + print_words('has been updated')
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
        page.replace_html "sms_inbox_#{@sms_inbox.id}", :partial => 'edit'
        page.visual_effect :highlight, "sms_inbox_#{@sms_inbox.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
        page << %Q{$("#{elem_id}").update(txt)}
      end
    end
  end

  # Show item
  def show
    @sms_inbox = SmsInbox.find_by_id(params[:id])
        
    render :update do |page| page.redirect_to :action => 'index' end if @sms_inbox.nil?
    
    @sms_inbox.update_attribute(:has_read, true)
    
    elem_id = "sms_inbox_offset_#{@sms_inbox.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "sms_inbox_#{@sms_inbox.id}", :partial => 'show'
      page.visual_effect :highlight, "sms_inbox_#{@sms_inbox.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @sms_inbox = SmsInbox.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @sms_inbox.nil?
    
    elem_id = "sms_inbox_offset_#{@sms_inbox.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "sms_inbox_#{@sms_inbox.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "sms_inbox_#{@sms_inbox.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @sms_inbox = SmsInbox.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @sms_inbox.nil? || !granted_to(:delete, @sms_inbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    sms_inbox_display_name = @sms_inbox.display_name
    if @sms_inbox.remove then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      #file_destroy(@sms_inbox.uploadfile) unless @sms_inbox.uploadfile.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "sms_inbox_#{@sms_inbox.id}"
        page.delay 1 do
          page.remove 'sms_inbox_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('sms inbox').capitalize_words + " \"#{sms_inbox_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "sms_inbox_#{@sms_inbox.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
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
    # return true if action == :delete and item.user_id == self.current_user.id
    # check also update here!
    
    # super admin can do anything
    return true if permit? 'superadmin | inboxadmin'
    
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
