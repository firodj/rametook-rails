class <%= controller_class_name %>Controller < ApplicationController
  before_filter :login_required, 
                :only => [:new, :edit, :create, :update, :destroy]
  
  # access_control :DEFAULT => 'superadmin'
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  
  verify  :xhr => true,
          :only => [:filter_cancel, :new_cancel, :close],
          :redirect_to => { :action => 'index' }
  verify  :method => :get, :only => [:show],
          :redirect_to => { :action => :list }
  verify  :method => :post, :only => [ :create ],
          :redirect_to => { :action => :list }
  verify  :method => :put, :only => [:update],
          :redirect_to => { :action => 'index' }
  verify  :method => :delete, :only => [:destroy],
          :redirect_to => { :action => 'index' }
  
  # list all fields to params for filter
  # pair of: param_key(show on url) => field_name(in model)
<% 
fields_params = [ ':text => :search_text' ]
model_instance.class.reflect_on_all_associations(:belongs_to).each { |belongs_to| fields_params <<[ ':' + belongs_to.primary_key_name.sub(/_id$/, '') + ' => :' + belongs_to.primary_key_name ] }
-%>
  ParamToField =   
  { <%= fields_params.join(",\n    ") %> }
      
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

<%- model_instance.class.reflect_on_all_associations(:belongs_to).each do |belongs_to| -%>
    if @search_filters[:<%= belongs_to.primary_key_name %>] then        
      filter_instance = <%= belongs_to.class_name %>.find_by_id(@search_filters[:<%= belongs_to.primary_key_name %>])
      if filter_instance then
        conditions_str << "<%= table_name + '.' + belongs_to.primary_key_name %> = ?"
        conditions << @search_filters[:<%= belongs_to.primary_key_name %>]
        @search_titles << ['<%= belongs_to.name.to_s.humanize.downcase %>', filter_instance]
      else
        @search_filters.delete(:<%= belongs_to.primary_key_name %>)
      end
    end
<% end -%>
    if @search_filters[:search_text] then
      search_fields = [<%= model_instance.class.content_columns.map{ |c| "'#{c.name}'" }.join(', ') %>]
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`<%= table_name %>`.`#{c}` LIKE ?" }.join(' OR ') + ')'
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
<% model_instance.class.reflect_on_all_associations(:belongs_to).each { |belongs_to| -%>
    @<%= belongs_to.name.to_s.pluralize %> = <%= belongs_to.class_name %>.find_all_for_select_option(blank) rescue [['ERROR','']]
<% } -%>
  end

<% unless suffix -%>
  # Default action
  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index
    list
  end
<% end -%>
  
<% for action in unscaffolded_actions -%>
  def <%= action %><%= suffix %>
  end

<% end -%>
  # List all items
  def list<%= suffix %>    
    conditions = build_list_options
    paginate_options = {:per_page => 10}
    paginate_options[:conditions] = conditions unless conditions.nil?
    
    # paginate don't know mau diapakaan neh!
    
    @<%= singular_name %>_pages, @<%= plural_name %> = paginate :<%= plural_name %>, paginate_options
        
    respond_to do |format|
      format.html { render :action => 'list' }
      format.xml  { render :xml => @<%= plural_name %>.to_xml }
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
  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show
    @<%= singular_name %> = <%= model_name %>.find_by_id(params[:id])
    
    return if reject_when_not_granted_to(:show, @<%= singular_name %>)
    
    respond_to do |format|
      format.js  { render_update_with_item :partial => 'show', :highlight => :white }
      format.html { redirect_to <%= plural_name %>_url }
      format.xml { render :xml => @<%= singular_name %>.to_xml }
    end
  end
  
  # Close Edit's form or Show
  def close
    @<%= singular_name %> = <%= model_name %>.find_by_id(params[:id])
    
    reject_action and return if @<%= singular_name %>.nil?
    
    render_update_with_item :highlight => :white
  end
  
  # Show New form
  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= singular_name %> = <%= model_name %>.new
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @<%= singular_name %>)
        
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
  # GET /<%= table_name %>/1;edit
  # GET /<%= table_name %>/1/edit
  # GET /<%= table_name %>/1.xml;edit
  # GET /<%= table_name %>/1/edit.xml
  def edit
    @<%= singular_name %> = <%= model_name %>.find_by_id(params[:id])
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @<%= singular_name %>)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    unless request.xhr? then
      redirect_to :action => 'index' 
    else
      render_update_with_item :partial => 'edit', :highlight => :white
    end
  end
  
  # Create item
  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  def create
    @<%= singular_name %> = <%= model_name %>.new(params[:<%= singular_name %>])
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @<%= singular_name %>)
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @<%= singular_name %>.save then
        flash[:notice] = [ print_words('<%= model_name.underscore.humanize.downcase %>').capitalize_words, 
          @<%= singular_name %>.display_name, print_words('has been created') ].join(' ')
        format.html { redirect_to <%= plural_name %>_url }  # :page => params[:page]
        format.xml  { head :created, :location => <%= singular_name %>_url(@<%= singular_name %>) }
      else
        format.html { render :partial => 'new_error', :layout => 'application' }
        format.xml  { render :xml => @<%= singular_name %>.errors.to_xml }
      end
    end
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update
    @<%= singular_name %> = <%= model_name %>.find_by_id(params[:id])
    
    # @<%= singular_name %>.attributes = params[:<%= singular_name %>]
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @<%= singular_name %>)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @<%= singular_name %>.update_attributes( params[:<%= singular_name %>] ) then
        flash[:notice] = [ print_words('<%= model_name.underscore.humanize.downcase %>').capitalize_words,
          @<%= singular_name %>.display_name, print_words('has been updated') ].join(' ')
        format.html { redirect_to <%= plural_name %>_url } # :page => params[:page]
        format.xml  { head :ok }
      else
        format.html { render :partial => 'edit_error', :layout => 'application' }
        format.xml  { render :xml => @<%= singular_name %>.errors.to_xml }
      end
    end
  end
  
  # Destroy item
  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy
    @<%= singular_name %> = <%= model_name %>.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    return if reject_when_not_granted_to(:destroy, @<%= singular_name %>)
    
    respond_to do |format|
      if @<%= singular_name %>.destroy then
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
        return true if permit? 'superadmin'
        return true
      when :show
        return true
      when :update
        return false unless logged_in?
        return true if permit? 'superadmin'
      when :destroy
        return false unless logged_in?
        return false unless item.can_destroyed?
        return true if permit? 'superadmin'
    end
    # otherwise prevent action
    return false
  end
  
  hide_action :reject_when_not_granted_to
  def reject_when_not_granted_to(action, item)
    if @<%= singular_name %>.nil? || !granted_to(action, @<%= singular_name %>) then
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
