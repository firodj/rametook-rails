class SmsRepliesController < ApplicationController
  before_filter :login_required, 
                :only => [:new, :edit, :destroy]
  
  # access_control :DEFAULT => 'superadmin'
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  
  verify  :xhr => true,
          :only => [:filter_cancel, :new_cancel, :show, :close],
          :redirect_to => { :action => 'index' }
  #verify  :method => :get, :only => [:destroy],
  #        :redirect_to => { :action => :list }
  verify  :method => :post, :only => [ :create ],
          :redirect_to => { :action => :list }
  verify  :method => :put, :only => [:update],
          :redirect_to => { :action => 'index' }
  verify  :method => :delete, :only => [:destroy],
          :redirect_to => { :action => 'index' }
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
  ParamToField =   
  { :text => :search_text }
      
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

    if @search_filters[:search_text] then
      search_fields = ['function', 'action', 'message', 'tags', 'help_info', 'active']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`sms_replies`.`#{c}` LIKE ?" }.join(' OR ') + ')'
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
  end

  # Default action
  # GET /sms_replies
  # GET /sms_replies.xml
  def index
    list
  end
  
  # List all items
  def list    
    conditions = build_list_options
    paginate_options = {:per_page => 10}
    paginate_options[:conditions] = conditions unless conditions.nil?
    
    # paginate don't know mau diapakaan neh!
    
    @sms_reply_pages, @sms_replies = paginate :sms_replies, paginate_options
        
    respond_to do |format|
      format.html { render :action => 'list' }
      format.xml  { render :xml => @sms_replies.to_xml }
    end
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

  # Show New's form
  # GET /sms_replies/1
  # GET /sms_replies/1.xml
  def show
    @sms_reply = SmsReply.find_by_id(params[:id])
    
    return if reject_when_not_granted_to(:show, @sms_reply)
    
    respond_to do |format|
      format.js  { render_update_with_item :partial => 'show', :highlight => :white }
      format.xml { render :xml => @sms_reply.to_xml }
    end
  end
  
  # Close Edit's form or Show
  def close
    @sms_reply = SmsReply.find_by_id(params[:id])
    
    reject_action and return if @sms_reply.nil?
    
    render_update_with_item :highlight => :white
  end
  
  # Show New form
  # GET /sms_replies/new
  # GET /sms_replies/new.xml
  def new
    @sms_reply = SmsReply.new
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @sms_reply)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    redirect_to :action => 'index' and return unless request.xhr?
    
    render :update do |page| 
      page.hide 'add_new_button'
      page['message'].hide
      page.replace_html "message", ''
      page.insert_html :after, "title", :partial => 'new'
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
  # GET /sms_replies/1;edit
  # GET /sms_replies/1/edit
  # GET /sms_replies/1.xml;edit
  # GET /sms_replies/1/edit.xml
  def edit
    @sms_reply = SmsReply.find_by_id(params[:id])
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @sms_reply)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    unless request.xhr? then
      redirect_to :action => 'index' 
    else
      render_update_with_item :partial => 'edit', :highlight => :white
    end
  end
  
  # Create item
  # POST /sms_replies
  # POST /sms_replies.xml
  def create
    @sms_reply = SmsReply.new(params[:sms_reply])
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @sms_reply)
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @sms_reply.save then
        flash[:notice] = [ print_words('sms reply').capitalize_words, 
          @sms_reply.display_name, print_words('has been created') ].join(' ')
        format.html { redirect_to sms_replies_url }  # :page => params[:page]
        format.xml  { head :created, :location => sms_reply_url(@sms_reply) }
      else
        format.html { render :partial => 'new_error', :layout => 'application' }
        format.xml  { render :xml => @sms_reply.errors.to_xml }
      end
    end
  end

  # PUT /sms_replies/1
  # PUT /sms_replies/1.xml
  def update
    @sms_reply = SmsReply.find_by_id(params[:id])
    
    # @sms_reply.attributes = params[:sms_reply]
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @sms_reply)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @sms_reply.update_attributes( params[:sms_reply] ) then
        flash[:notice] = [ print_words('sms reply').capitalize_words,
          @sms_reply.display_name, print_words('has been updated') ].join(' ')
        format.html { redirect_to sms_replies_url } # :page => params[:page]
        format.xml  { head :ok }
      else
        format.html { render :partial => 'edit_error', :layout => 'application' }
        format.xml  { render :xml => @sms_reply.errors.to_xml }
      end
    end
  end
  
  # Destroy item
  # DELETE /sms_replies/1
  # DELETE /sms_replies/1.xml
  def destroy
    @sms_reply = SmsReply.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    return if reject_when_not_granted_to(:destroy, @sms_reply)
    
    respond_to do |format|
      if @sms_reply.destroy then
        format.js   { render_update_with_item :fade => true, :message => print_words('has been deleted') }
        format.xml  { head :ok }
      else
        format.js   { render_update_with_item :highlight => :red }
        format.xml  { head :not_modified }
      end
    end
  end
  
  helper_method :granted_to
  # Item grantted to do
  # only registered user can do :create, :update, and :delete
  def granted_to(action, item)
    case action
      when :create
        # item may nil if action is :create
        return false unless logged_in?
        return true if permit? 'developer'
      when :show
        return true
      when :update
        return false unless logged_in?
        return true if permit? 'superadmin | developer'
      when :destroy
        return false unless logged_in?
        return false unless item.can_destroyed?
        return true if permit? 'developer'
    end
    # otherwise prevent action
    return false
  end
  
  hide_action :reject_when_not_granted_to
  def reject_when_not_granted_to(action, item)
    if @sms_reply.nil? || !granted_to(action, @sms_reply) then
      reject_action
      return true
    end
  end
  
  hide_action :reject_action
  def reject_action
    if request.xhr?
      render :update do |page| page.redirect_to :action => 'index' end
    else
      redirect_to :action => 'index'
    end
  end
  
  # get field name to param key 
  helper_method :field_to_param
  def field_to_param(field_id)
    ParamToField.index(field_id) || field_id
  end

  hide_action :render_update_with_item
  # :partial => ''
  # :locals => {}
  # :highlight => :normal | :red | :white
  # :fade => true | false
  # :message => ''
  def render_update_with_item(options = {})
    @render_options = options
    return render :action => 'item_update'
  end
end
