class SmsOutboxesController < ApplicationController
  before_filter :login_required
                #:only => [:new, :edit, :destroy]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :new, :edit ],
  #        :redirect_to => { :action => :list }
  # verify :method => :delete, :only => [:destroy],
  #        :redirect_to => { :action => :list }
  
  verify  :xhr => true,
          :only => [:filter_cancel, :new_cancel, :show, :close, :destroy, :update_progress],
          :redirect_to => { :action => 'index' }
  verify  :method => :post,
          :only => [:filter],
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

    if !permit?('superadmin | outboxadmin') then
      # user id
      conditions_str << 'created_by_user_id = ?'
      conditions     << self.current_user.id
      
      # don't include removed
      conditions_str << 'removed = ?'
      conditions     << false
    end    
    
    if @search_filters[:search_text] then
      search_fields = %w(number message)
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`sms_outboxes`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << "%#{@search_filters[:search_text]}%" }
      end   
      @search_titles << ['text', @search_filters[:search_text]]      
    end
    
    # just grouped
#    conditions_str << 'group_id IS ?'
#    conditions     << nil
    
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
    @sms_templates = SmsTemplate.find_all_for_select_option('')
    @message_signature = "\n--\n#{self.current_user.display_name.truncate(24)}"
    @sms_recipients = AddressbookContact.find(:all, :order => 'name ASC')
    
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
    paginate_options[:order] = 'created_at DESC'
    @sms_outbox_pages, @sms_outboxes = paginate :sms_outbox, paginate_options
  end

=begin
  def list_for_admin    
    conditions = build_list_options(:admin => true)
    paginate_options = {:per_page => 20}
    paginate_options[:conditions] = conditions unless conditions.nil?
    paginate_options[:order] = 'sent_time DESC'
    @sms_outbox_pages, @sms_outboxes = paginate :sms_outboxes, paginate_options
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
    @sms_outbox = SmsOutbox.new
   
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @sms_outbox)
        
    # Setup default non-editable value    
    build_lookup_belongs
 
    if !params[:commit] then
      if !params[:recipients] then
        params[:recipients] = {}
        @sms_recipients.each { |contact| params[:recipients][contact.id.to_s] = true }
      end      
    end
    # redirect_to :action => 'index' and return unless request.xhr?
    
    if request.xhr? then
    render :update do |page|
      page.hide 'add_new_button'
      page['message'].hide
      page.replace_html "message", ''
      page.insert_html :after, "title", :partial => 'new'
    end
    end
  end
  
  # Close new's form
  def new_cancel
  end
  
  def create
    @sms_outbox = SmsOutbox.new(params[:sms_outbox])
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @sms_outbox)
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    if @sms_outbox.save then
      flash[:notice] = [ print_words('sms_outbox').capitalize_words, 
          @sms_outbox.display_name, print_words('has been created') ].join(' ')
      redirect_to :action => 'list', :page => params[:page]
    else
      render :partial => 'new_error', :layout => 'application'
    end
  end
  
=begin
  # Show Edit's form, and then Update item
  def edit
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    # Get the uploaded file data first !
    #uploadfile = params[:sms_outbox].delete(:uploadfile) if params[:sms_outbox]
    @sms_outbox.attributes = params[:sms_outbox]
      
    # Check if item found and granted to be updated
    if @sms_outbox.nil? || !granted_to(:update, @sms_outbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    elem_id = "sms_outbox_offset_#{@sms_outbox.id}"
    if params[:sms_outbox]

      if @sms_outbox.save        

        flash[:notice] = print_words('sms outbox').capitalize_words + " \"#{@sms_outbox.display_name}\" " + print_words('has been updated')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :partial => 'edit_error', :layout => 'application'
      end
    else
      redirect_to :action => 'index' and return unless request.xhr?
      
      render_update_with_item :partial => 'edit', :highlight => :white
      
    end
  end
=end

  # Show item
  def show
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @sms_outbox.nil?
    
    render_update_with_item :partial => 'show', :highlight => :white
  end
  
  # Close Edit's form or Show
  def close
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @sms_outbox.nil?
    
    render_update_with_item :highlight => :white
  end
  
  # Destroy item
  def destroy
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @sms_outbox.nil? || !granted_to(:delete, @sms_outbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    if @sms_outbox.remove_all then    
      render_update_with_item :fade => true, :message => print_words('has been deleted')
    else
      render_update_with_item :highlight => :red
    end
  end
  
  def cancel_sending
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @sms_outbox.nil? || !granted_to(:delete, @sms_outbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    if @sms_outbox.cancel_all then
      render_update_with_item :highlight => true, :message => print_words('has been canceled')
    else
      render_update_with_item :highlight => :red
    end
  end
  
  def resend_sending
    @sms_outbox = SmsOutbox.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @sms_outbox.nil? || !granted_to(:delete, @sms_outbox) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    if @sms_outbox.resend_all then
      render_update_with_item :highlight => true, :message => print_words('has been resent')
    else
      render_update_with_item :highlight => :red
    end
  end
  
  def update_progress
    sms_outbox_status = {:multi => {}, :single => {}}
    params[:sms_outbox_ids].split(',').each { |sms_outbox_id|
      sms_outbox = SmsOutbox.find_by_id(sms_outbox_id)
      
      sms_outbox_status[:multi][sms_outbox.id] = sms_outbox.status
      
      sms_outbox.sms_outbox_recipients.each { |recipient|
        sms_outbox_status[:single][recipient.id] = recipient.status 
        #   + Time.now.strftime(' %S') # if recipient 
      }
      
    } if params[:sms_outbox_ids]
    render :json => sms_outbox_status.to_json
  end
  
  # Item grantted to do
  helper_method :granted_to
  def granted_to(action, item)
    # only registered user can do :create, :update, and :delete
  	return false unless logged_in?
  	
  	# only delete item that can be destroyed
    return false if action == :delete and not item.can_destroyed?
    return true if action == :delete and item.created_by == self.current_user.id
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
  
  hide_action :reject_action
  def reject_action
    if request.xhr?
      render :update do |page| page.redirect_to :action => 'index' end
    else
      redirect_to :action => 'index'
    end
  end
  
  hide_action :reject_when_not_granted_to
  def reject_when_not_granted_to(action, item)
    if @sms_outbox.nil? || !granted_to(action, @sms_outbox) then
      reject_action
      return true
    end
  end
end
