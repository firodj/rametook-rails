class AddressbookGroupsController < ApplicationController
  before_filter :login_required 
                #:only => [:new, :edit, :destroy]
  access_control :DEFAULT => 'superadmin | addressbookadmin'
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :new, :edit ],
  #        :redirect_to => { :action => :list }
  # verify :method => :delete, :only => [:destroy],
  #        :redirect_to => { :action => :list }
  
  verify  :xhr => true,
          :only => [:filter_cancel, :new_cancel, :show, :close, :destroy, :update_contact_result],
          :redirect_to => { :action => 'index' }
  verify  :method => :post,
          :only => [:filter, :new, :edit],
          :redirect_to => { :action => 'index' }
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
  ParamToField =   
  { :text => :search_text,
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

    #if @search_filters[:user_id] then        
    #  filter_instance = User.find_by_id(@search_filters[:user_id])
    #  if filter_instance then
    #    conditions_str << "addressbook_groups.user_id = ?"
    #   conditions << self.current_user.id #@search_filters[:user_id]
    #    @search_titles << ['user', filter_instance]
    #  else
    #    @search_filters.delete(:user_id)
    #  end
    #end
    
    if @search_filters[:search_text] then
      search_fields = ['name']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`addressbook_groups`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << "%#{@search_filters[:search_text]}%" }
      end   
      @search_titles << ['text', @search_filters[:search_text]]      
    end
    
    #conditions_str << "addressbook_groups.public = ?"
    #conditions << params[:public]
      
    #if !params[:public] then
    #  conditions_str << "addressbook_groups.user_id = ? "
    #  conditions << self.current_user.id
    #else
    #  if !permit?('superadmin') then
    #    conditions_str << "(addressbook_groups.department_id IS ? OR addressbook_groups.department_id = ?)"
    #    conditions << nil
    #    conditions << self.current_user.department_id
    #  end
    #end
    
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
    @users = User.find_all_for_select_option(blank) rescue [['ERROR','']]
    @privacies = [[print_words('private').capitalize_words,false],[print_words('public').capitalize_words,true]]
    @departments = Department.find_all_for_select_option(blank) rescue [['ERROR','']]
    if !permit?('superadmin') then
      @departments.delete_if { |text, id| id != self.current_user.department_id }
    end
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

    @addressbook_group_pages, @addressbook_groups = paginate :addressbook_groups, paginate_options
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
    @addressbook_group = AddressbookGroup.new(params[:addressbook_group])
    @addressbook_group.public = params[:public] unless params[:public].nil?
    @addressbook_group.public ||= true
    
    # Check if item ready and granted to be created
    if @addressbook_group.nil? || !granted_to(:create, @addressbook_group) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    # setup automatic default value
    @addressbook_group.user = self.current_user
    @addressbook_group.department_id = nil if !@addressbook_group.public
    
    build_lookup_belongs
    
    if params[:addressbook_group]
    
      # new_or_edit_addressbook_group_phones
      
      if @addressbook_group.save

        
        flash[:notice] = print_words('addressbook group').capitalize_words + " \"#{@addressbook_group.display_name}\" " + print_words('has been created')
        redirect_to :action => 'list_' + (@addressbook_group.public ? 'public' : 'private'), :page => params[:page]
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

  hide_action :new_or_edit_addressbook_group_phones
  def new_or_edit_addressbook_group_phones

    member_contacts = {}
    params[:member_contacts].each { |member_contact|
      contact_id, field_id = member_contact.split(',')
      contact_id = contact_id.to_i
      member_contacts[contact_id] ||= {}
      member_contacts[contact_id][field_id] = true
    } if !params[:member_contacts].blank? 
    
    @group_phones_to_remove = []
    @addressbook_group.addressbook_group_phones.each { |group_phone|
      if member_contacts[ group_phone.addressbook_contact.id ] &&
        member_contacts[ group_phone.addressbook_contact.id ][ group_phone.field ] then
        member_contacts[ group_phone.addressbook_contact.id ].delete( group_phone.field )
        member_contacts.delete(group_phone.addressbook_contact.id) if member_contacts[ group_phone.addressbook_contact.id ].empty?
      else
        @group_phones_to_remove << group_phone
      end
    }
    
    @group_phones_to_add = []
    member_contacts.each_pair { |contact_id, fields_ids|
      fields_ids.keys.each { |field_id|
        @group_phones_to_add << AddressbookGroupPhone.new(:addressbook_contact_id => contact_id, :field => field_id)
      }
    }

  end
  
  # Show Edit's form, and then Update item
  def edit
    @addressbook_group = AddressbookGroup.find_by_id(params[:id])
    @addressbook_group.attributes = params[:addressbook_group]
    
    # Check if item found and granted to be updated
    if @addressbook_group.nil? || !granted_to(:update, @addressbook_group) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    #
    @addressbook_group.department_id = nil if !@addressbook_group.public
    
    build_lookup_belongs
    
    elem_id = "addressbook_group_offset_#{@addressbook_group.id}"
    if params[:addressbook_group]

        
      if @addressbook_group.save


        flash[:notice] = print_words('addressbook group').capitalize_words + " \"#{@addressbook_group.display_name}\" " + print_words('has been updated')
        redirect_to :action => 'list_' + (@addressbook_group.public ? 'public' : 'private'), :page => params[:page]
      else
        render :partial => 'edit_error', :layout => 'application'
      end
    else
      redirect_to :action => 'index' and return unless request.xhr?
      render :update do |page| 
        page << %Q{txt = $("#{elem_id}").innerHTML}
        page['message'].hide
        page.replace_html "message", ''
        page.replace_html "addressbook_group_#{@addressbook_group.id}", :partial => 'edit'
        page.visual_effect :highlight, "addressbook_group_#{@addressbook_group.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
        page << %Q{$("#{elem_id}").update(txt)}
      end
    end
  end

  # Show item
  def show
    @addressbook_group = AddressbookGroup.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @addressbook_group.nil?
    
    elem_id = "addressbook_group_offset_#{@addressbook_group.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "addressbook_group_#{@addressbook_group.id}", :partial => 'show'
      page.visual_effect :highlight, "addressbook_group_#{@addressbook_group.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @addressbook_group = AddressbookGroup.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @addressbook_group.nil?
    
    elem_id = "addressbook_group_offset_#{@addressbook_group.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "addressbook_group_#{@addressbook_group.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "addressbook_group_#{@addressbook_group.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @addressbook_group = AddressbookGroup.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @addressbook_group.nil? || !granted_to(:delete, @addressbook_group) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    addressbook_group_display_name = @addressbook_group.display_name
    if @addressbook_group.destroy then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      #file_destroy(@addressbook_group.uploadfile) unless @addressbook_group.uploadfile.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "addressbook_group_#{@addressbook_group.id}"
        page.delay 1 do
          page.remove 'addressbook_group_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('addressbook group').capitalize_words + " \"#{addressbook_group_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "addressbook_group_#{@addressbook_group.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
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
    return (item.user == self.current_user) if [:delete, :update].include?(action)
    
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
  
  def update_contact_result
    contacts = []
    
    params[:public] = {'true' => true, 'false' => false}[params[:public]]
    if !params[:public].nil?
      conditions = {:public => params[:public]}
      conditions[:user_id] = self.current_user.id if !params[:public]
      conditions[:department_id] = params[:department_id] if !params[:department_id].blank?
      
      AddressbookContact.find(:all, :conditions => conditions, :order => 'name').each { |e| 
        %w(phone mobile1 mobile2).each { |f|
          contacts << [e.id, f, e.display_name, e[f]] if !e[f].blank?
        }
      }
    end
    render :json => contacts.to_json
  end
  
end
