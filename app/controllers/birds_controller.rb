class BirdsController < ApplicationController
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

    if @search_filters[:user_id] then        
      filter_instance = User.find_by_id(@search_filters[:user_id])
      if filter_instance then
        conditions_str << "birds.user_id = ?"
        conditions << @search_filters[:user_id]
        @search_titles << ['user', filter_instance]
      else
        @search_filters.delete(:user_id)
      end
    end
    if @search_filters[:search_text] then
      search_fields = ['name', 'description', 'die_at', 'created_at', 'fine', 'sleep_at', 'image']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`birds`.`#{c}` LIKE ?" }.join(' OR ') + ')'
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
    @users = User.find_all_for_select_option(blank) rescue [['ERROR','']]
  end

  # Default action
  # GET /birds
  # GET /birds.xml
  def index
    list
  end
  
  # List all items
  def list    
    conditions = build_list_options
    paginate_options = {:per_page => 10}
    paginate_options[:conditions] = conditions unless conditions.nil?
    
    # paginate don't know mau diapakaan neh!
    
    @bird_pages, @birds = paginate :birds, paginate_options
        
    respond_to do |format|
      format.html { render :action => 'list' }
      format.xml  { render :xml => @birds.to_xml }
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
  # GET /birds/1
  # GET /birds/1.xml
  def show
    @bird = Bird.find_by_id(params[:id])
    
    return if reject_when_not_granted_to(:show, @bird)
    
    respond_to do |format|
      format.js  { render_update_with_item :partial => 'show', :highlight => :white }
      format.html { redirect_to birds_url }
      format.xml { render :xml => @bird.to_xml }
    end
  end
  
  # Close Edit's form or Show
  def close
    @bird = Bird.find_by_id(params[:id])
    
    reject_action and return if @bird.nil?
    
    render_update_with_item :highlight => :white
  end
  
  # Show New form
  # GET /birds/new
  # GET /birds/new.xml
  def new
    @bird = Bird.new
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @bird)
        
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
  # GET /birds/1;edit
  # GET /birds/1/edit
  # GET /birds/1.xml;edit
  # GET /birds/1/edit.xml
  def edit
    @bird = Bird.find_by_id(params[:id])
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @bird)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    unless request.xhr? then
      redirect_to :action => 'index' 
    else
      render_update_with_item :partial => 'edit', :highlight => :white
    end
  end
  
  # Create item
  # POST /birds
  # POST /birds.xml
  def create
    @bird = Bird.new(params[:bird])
    
    # Check if item ready and granted to be created
    return if reject_when_not_granted_to(:create, @bird)
    
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @bird.save then
        flash[:notice] = [ print_words('bird').capitalize_words, 
          @bird.display_name, print_words('has been created') ].join(' ')
        format.html { redirect_to birds_url }  # :page => params[:page]
        format.xml  { head :created, :location => bird_url(@bird) }
      else
        format.html { render :partial => 'new_error', :layout => 'application' }
        format.xml  { render :xml => @bird.errors.to_xml }
      end
    end
  end

  # PUT /birds/1
  # PUT /birds/1.xml
  def update
    @bird = Bird.find_by_id(params[:id])
    
    # @bird.attributes = params[:bird]
      
    # Check if item found and granted to be updated
    return if reject_when_not_granted_to(:update, @bird)
        
    # Setup default non-editable value
    
    build_lookup_belongs
    
    respond_to do |format|
      if @bird.update_attributes( params[:bird] ) then
        flash[:notice] = [ print_words('bird').capitalize_words,
          @bird.display_name, print_words('has been updated') ].join(' ')
        format.html { redirect_to birds_url } # :page => params[:page]
        format.xml  { head :ok }
      else
        format.html { render :partial => 'edit_error', :layout => 'application' }
        format.xml  { render :xml => @bird.errors.to_xml }
      end
    end
  end
  
  # Destroy item
  # DELETE /birds/1
  # DELETE /birds/1.xml
  def destroy
    @bird = Bird.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    return if reject_when_not_granted_to(:destroy, @bird)
    
    respond_to do |format|
      if @bird.destroy then
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
    if @bird.nil? || !granted_to(action, @bird) then
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
