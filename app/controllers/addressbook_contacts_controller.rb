class AddressbookContactsController < ApplicationController
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
          :only => [:filter, :new],
          :redirect_to => { :action => 'index' }
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
  ParamToField =   
  { :text => :search_text,
    :department => :department_id,
    :addressbook_group => :addressbook_group_id,
    :user => :user_id }
      
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

    if @search_filters[:addressbook_group_id] then        
      if filter_instance = AddressbookGroup.find_by_id(@search_filters[:addressbook_group_id])    
        conditions_str << "addressbook_group_phones.addressbook_group_id = ?"
        conditions << @search_filters[:addressbook_group_id]
        @search_titles << ['addressbook group', filter_instance]
      else
        @search_filters.delete(:addressbook_group_id)
      end
    end

=begin
    if @search_filters[:department_id] then        
      filter_instance = Department.find_by_id(@search_filters[:department_id])
      if filter_instance then
        conditions_str << "addressbook_contacts.department_id = ?"
        conditions << @search_filters[:department_id]
        @search_titles << ['department', filter_instance]
      else
        @search_filters.delete(:department_id)
      end
    end
    if @search_filters[:user_id] then        
      filter_instance = User.find_by_id(@search_filters[:user_id])
      if filter_instance then
        conditions_str << "addressbook_contacts.user_id = ?"
        conditions << @search_filters[:user_id]
        @search_titles << ['user', filter_instance]
      else
        @search_filters.delete(:user_id)
      end
    end
=end
    
    #conditions_str << "addressbook_contacts.public = ?"
    #conditions << params[:public]
      
    #if !params[:public] then
    #  conditions_str << "addressbook_contacts.user_id = ? "
    #  conditions << self.current_user.id
    #end
    
    if @search_filters[:search_text] then
      search_fields = %w(name email description address city country birthday)
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`addressbook_contacts`.`#{c}` LIKE ?" }.join(' OR ') + ')'
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
    @departments = Department.find_all_for_select_option(blank) rescue [['ERROR','']]
    @users = User.find_all_for_select_option(blank) rescue [['ERROR','']]
    @privacies = [[print_words('private').capitalize_words,false],[print_words('public').capitalize_words,true]]
            
    @addressbook_groups = AddressbookGroup.find_all_for_select_option(blank) rescue [['ERROR','']]
    
  end

  # Default action
  def index
    list_private
  end
  
  # List all items
  def list    
    conditions = build_list_options
    paginate_options = {:per_page => 100}
    paginate_options[:conditions] = conditions unless conditions.nil?
    paginate_options[:order] = 'name ASC'
    paginate_options[:include] = [:addressbook_group_phones]
    @addressbook_contact_pages, @addressbook_contacts = paginate :addressbook_contacts, paginate_options
  end

  def list_private
    params[:public] = false
    list
    render :action => 'list'
  end
  
  def list_public
    params[:public] = true
    list
    render :action => 'list'
  end

  # Show filter's form
  def filter
    build_lookup_belongs('')
    if params[:commit] or params[:clear] then
      params_filter = {:action => 'list_' + (params[:public] ? 'public' : 'private')} # add other default filters
       
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
    @addressbook_contact = AddressbookContact.new(params[:addressbook_contact])
    @addressbook_contact.public = params[:public] unless params[:public].nil?
    @addressbook_contact.public ||= false
    
    # Check if item ready and granted to be created
    if @addressbook_contact.nil? || !granted_to(:create, @addressbook_contact) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end

    # setup automatic default value
    @addressbook_contact.user = self.current_user
    
    build_lookup_belongs
    
    if params[:addressbook_contact] then
      if @addressbook_contact.save then
        #@addressbook_contact.update_groups( params[:addressbook_group_ids] )
        
        flash[:notice] = print_words('addressbook contact').capitalize_words + " \"#{@addressbook_contact.display_name}\" " + print_words('has been created')
       
        redirect_to :action => 'list_' + (@addressbook_contact.public ? 'public' : 'private'), :page => params[:page]
      else
        render :action => 'new' #, :layout => 'application'
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
    @addressbook_contact = AddressbookContact.find_by_id(params[:id])
    
    # Check if item found and granted to be updated
    if @addressbook_contact.nil? || !granted_to(:update, @addressbook_contact) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    elem_id = "addressbook_contact_offset_#{@addressbook_contact.id}"
    if params[:addressbook_contact]
      params[:addressbook_contact][:image] = false if params[:removeimage]
      
      if @addressbook_contact.update_attributes(params[:addressbook_contact])
        #@addressbook_contact.update_groups( params[:addressbook_group_ids] )

        flash[:notice] = print_words('addressbook contact').capitalize_words + " \"#{@addressbook_contact.display_name}\" " + print_words('has been updated')
        
        redirect_to :action => 'list_' + (@addressbook_contact.public ? 'public' : 'private'), :page => params[:page]
      else
        render :action => 'edit' #_error, :layout => 'application'
      end
    else
      #redirect_to :action => 'index' and return unless
      if request.xhr? then
        render :update do |page| 
          page << %Q{txt = $("#{elem_id}").innerHTML}
          page['message'].hide
          page.replace_html "message", ''
          page.replace_html "addressbook_contact_#{@addressbook_contact.id}", :partial => 'edit'
          page.visual_effect :highlight, "addressbook_contact_#{@addressbook_contact.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
          page << %Q{$("#{elem_id}").update(txt)}
        end
      end
    end
  end

  # Show item
  def show
    @addressbook_contact = AddressbookContact.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @addressbook_contact.nil?
    
    elem_id = "addressbook_contact_offset_#{@addressbook_contact.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "addressbook_contact_#{@addressbook_contact.id}", :partial => 'show'
      page.visual_effect :highlight, "addressbook_contact_#{@addressbook_contact.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @addressbook_contact = AddressbookContact.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @addressbook_contact.nil?
    
    elem_id = "addressbook_contact_offset_#{@addressbook_contact.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "addressbook_contact_#{@addressbook_contact.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "addressbook_contact_#{@addressbook_contact.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @addressbook_contact = AddressbookContact.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @addressbook_contact.nil? || !granted_to(:delete, @addressbook_contact) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    addressbook_contact_display_name = @addressbook_contact.display_name
    if @addressbook_contact.destroy then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      file_destroy(@addressbook_contact.image) unless @addressbook_contact.image.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "addressbook_contact_#{@addressbook_contact.id}"
        page.delay 1 do
          page.remove 'addressbook_contact_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('addressbook contact').capitalize_words + " \"#{addressbook_contact_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "addressbook_contact_#{@addressbook_contact.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
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
    #return false if action == :delete and (self.current_user.business_contact == item)
        
    # check also update here!
    
    # super admin can do anything
    return true if permit? 'superadmin | addressbookadmin'
    return (item.user == self.current_user) if action == :update

    # check item data with @current_user's role, 
    # item may nil if action is :create
    #return true if action == :create
    
    # otherwise prevent action
		false
  end
  
  # get field name to param key 
  helper_method :field_to_param
  def field_to_param(field_id)
    ParamToField.index(field_id) || field_id
  end
  
  helper_method :partial_content_for_phone
  def partial_content_for_phone
    render_to_string(:partial => 'phone', :object => AddressbookPhone.new(:name => 'Mobile')) 
  end
end
