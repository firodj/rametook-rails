class DepartmentsController < ApplicationController
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
          
  hide_action :build_list_options
  # Build +conditions+ from +session filters+
  def build_list_options
    conditions = []
    conditions_str = []
    
    @search_titles = []
  
    search_filters = get_search_filters

    if search_filters[:parent_id] then        
      filter_instance = Department.find_by_id(search_filters[:parent_id])
      if filter_instance then
        conditions_str << "departments.parent_id = ?"
        conditions << search_filters[:parent_id]
        filter_display_name = filter_instance.respond_to?(:display_name) ? filter_instance.display_name : filter_instance.id
        @search_titles << [print_words('parent').capitalize_words, filter_display_name]
      end
    end
    if search_filters[:search_text] then
      search_text = "%#{search_filters[:search_text]}%"
      search_fields = ['name']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`departments`.`#{c}` LIKE ?" }.join(' OR ') + ')'
        search_fields.size.times { conditions << search_text }
      end   
      @search_titles << [print_words('text').capitalize_words, search_filters[:search_text]]      
    end
    
    conditions.unshift( conditions_str.join(' AND ') ) unless conditions.empty?  
  end

  hide_action :build_lookup_belongs
  # Build instance variable from belongs_to
  def build_lookup_belongs(blank = nil)
    # TODO: Remove rescue statement
    @parents = Department.find_all_for_select_option(blank) rescue @parents = [['ERROR','']]
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
    
    @department_pages, @departments = paginate :departments, paginate_options
  end

  # Show filter's form
  def filter
    build_lookup_belongs('')
    search_filters = {}
    if params[:commit] or params[:clear] then
      params.each do |k,v|
        next if ['commit','action','controller'].include? k.to_s
        search_filters[k.to_sym] = v if v and !v.empty?
      end if not params[:clear]
      set_search_filters search_filters
      redirect_to :action => 'list'
    else
      begin
        redirect_to :action => 'index' and return unless request.xhr?
        search_filters = get_search_filters
        render :update do |page|
          page.hide 'filter_button'
          page['message'].hide
          page.replace_html "message", ''
          page.insert_html :after, "title", :partial => 'filter', :locals => {:search_filters => search_filters}
        end
      rescue => exception_raise_detail
        ajax_show_exception(exception_raise_detail)
      end
    end
  end
  
  # Close filter's form
  def filter_cancel
    render :update do |page| 
      page.remove 'filter_form'
      page.show 'filter_button'
    end
  rescue => exception_raise_detail
    ajax_show_exception(exception_raise_detail)
  end

  # Show New's form, and then Create item
  def new
    @department = Department.new(params[:department])
    
    # Check if item ready and granted to be created
    if @department.nil? || !granted_to(:create, @department) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    @parents = @department.find_available_parents_for_select_option('- root -')
    
    if params[:department]
      if @department.save
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ##
        #@department.uploadfile = if params[:department][:uploadfile].class == StringIO then
        #  new_uploadfile = SHA1.new(Time.now.to_s).to_s+params[:department][:uploadfile].original_filename
        #  File.open("#{RAILS_ROOT}/public/files/#{new_uploadfile}", "wb") do |f|  
        #    f.write(params[:department][:uploadfile].read)
        #  end
        #  new_uploadfile
        #else
        #  nil # default value
        #end
        #@department.save # save again

        flash[:notice] = print_words('department').capitalize_words + " \"#{@department.display_name}\" " + print_words('has been created')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :partial => 'new_error', :layout => 'application'
      end  
    else
      begin
        redirect_to :action => 'index' and return unless request.xhr?
        render :update do |page| 
          page.hide 'add_new_button'
          page['message'].hide
          page.replace_html "message", ''
          page.insert_html :after,"title", :partial => 'new'
        end
      rescue => exception_raise_detail
        ajax_show_exception(exception_raise_detail)
      end
    end    
  end
  
  # Close new's form
  def new_cancel
    render :update do |page| 
      page.remove 'new_form'
      page.show 'add_new_button'
    end
  rescue => exception_raise_detail
    ajax_show_exception(exception_raise_detail)
  end

  # Show Edit's form, and then Update item
  def edit
    @department = Department.find_by_id(params[:id])
    
    # Check if item found and granted to be updated
    if @department.nil? || !granted_to(:update, @department) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    @parents = @department.find_available_parents_for_select_option('- root -')
    
    elem_id = "department_offset_#{@department.id}"
    if params[:department]
      ## It's to help if you need to upload file/images, DB field name: image
      ## Check the form field and don't forget to set the multipart=true 
      ##
      #if params[:updateimage].blank?
      #  params[:department][:image] = @department.images
      #else
      #  new_image = SHA1.new(Time.now.to_s).to_s
      #  File.open("#{RAILS_ROOT}/public/images/#{new_image}.jpg", "wb") do |f|  
      #    f.write(params[:department][:image].read)
      #  end
      #  params[:department][:image] = "#{new_image}.jpg"
      #end
      if @department.update_attributes(params[:department])
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ## And add an check box button to delete file, name: removefile
        ##
        #@department.userfile = 
        #  if params[:department][:uploadfile].class == StringIO then
        #    file_destroy(@department.uploadfile) unless @department.uploadfile.nil? rescue nil # delete if not default value
        #    new_uploadfile = SHA1.new(Time.now.to_s).to_s+params[:department][:uploadfile].original_filename
        #    File.open("#{RAILS_ROOT}/public/files/#{new_uploadfile}", "wb") do |f|
        #      f.write(params[:department][:uploadfile].read)
        #    end        
        #    new_uploadfile
        #  else
        #    if params[:removefile].blank?
        #      @department.uploadfile # no change
        #    else 
        #      file_destroy(@department.uploadfile) unless @department.uploadfile.nil? rescue nil # delete if not default value
        #      nil # default value
        #    end
        #  end
        #@department.save #save again

        flash[:notice] = print_words('department').capitalize_words + " \"#{@department.display_name}\" " + print_words('has been updated')
        redirect_to :action => 'list', :page => params[:page]
      else
        render :partial => 'edit_error', :layout => 'application'
      end
    else
      begin
        redirect_to :action => 'index' and return unless request.xhr?
        render :update do |page| 
          page << %Q{txt = $("#{elem_id}").innerHTML}
          page['message'].hide
          page.replace_html "message", ''
          page.replace_html "department_#{@department.id}", :partial => 'edit'
          page.visual_effect :highlight, "department_#{@department.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
          page << %Q{$("#{elem_id}").update(txt)}
        end
      rescue => exception_raise_detail
        ajax_show_exception(exception_raise_detail)
      end
    end
  end

  # Show item
  def show
    @department = Department.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @department.nil?
    
    elem_id = "department_offset_#{@department.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "department_#{@department.id}", :partial => 'show'
      page.visual_effect :highlight, "department_#{@department.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  rescue => exception_raise_detail
    ajax_show_exception(exception_raise_detail)
  end
  
  # Close Edit's form or Show
  def close
    @department = Department.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @department.nil?
    
    elem_id = "department_offset_#{@department.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "department_#{@department.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "department_#{@department.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  rescue => exception_raise_detail
    ajax_show_exception(exception_raise_detail)
  end
  
  # Destroy item
  def destroy
    @department = Department.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @department.nil? || !granted_to(:delete, @department) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    department_display_name = @department.display_name
    if @department.destroy then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      #file_destroy(@department.uploadfile) unless @department.uploadfile.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "department_#{@department.id}"
        page.delay 1 do
          page.remove 'department_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('department').capitalize_words + " \"#{department_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "department_#{@department.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
      end
    end
  rescue => exception_raise_detail
    ajax_show_exception(exception_raise_detail) 
  end
  
  # Item grantted to do
  helper_method :granted_to
  def granted_to(action, item)
    # only registered user can do :create, :update, and :destroy
  	return false unless logged_in?
  	
  	# only delete item that can be destroyed
    return false if action == :delete and not item.can_destroyed?
    
    # super admin can do anything
    return true if permit? 'superadmin'
    
    # check item data with @current_user's role, 
    # item may nil if action is :create
    
    # otherwise prevent action
		false
  end   

  # Print Report
  # def print_report
  #   require 'report_sheet'
  #
  #   conditions = build_list_options   
  #   exim_template = EximTemplate.find(:first, :conditions => {:class_name => 'Department'})
  #   pdf = ReportSheet.render_template(exim_template, :pdf,
  #     {:conditions => conditions, :search_titles => @search_titles} )
  #   file_name = controller_name + Time.now.strftime(' %Y%m%d.pdf')
  #   send_data pdf, :filename => file_name, :type => "application/pdf" 
  # end
end
