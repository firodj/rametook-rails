class LanguagesController < ApplicationController
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
  @@param_to_field = 
  # param_key(show on url) => field_name(model)/whatever
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
      unless (kf = @@param_to_field[kp.to_sym]).nil? then
        @search_filters[ kf ] = v
        params_keys[ kf ] = kp
        true
      end
    }

    if @search_filters[:search_text] then
      search_fields = ['plugins', 'name', 'value', 'language']
      unless search_fields.empty? then
        conditions_str << '(' + search_fields.map{ |c| "`languages`.`#{c}` LIKE ?" }.join(' OR ') + ')'
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
    
    @language_pages, @languages = paginate :languages, paginate_options
  end

  # Show filter's form
  def filter
    build_lookup_belongs('')
    if params[:commit] or params[:clear] then
      params_filter = {:action => 'list'} # add other default filters
      params.each { |kp,v|
        kf = @@param_to_field[kp.to_sym]
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
    @language = Language.new(params[:language])
    
    # Check if item ready and granted to be created
    if @language.nil? || !granted_to(:create, @language) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    if params[:language]
      if @language.save
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ##
        #@language.uploadfile = if params[:language][:uploadfile].class == StringIO then
        #  new_uploadfile = SHA1.new(Time.now.to_s).to_s+params[:language][:uploadfile].original_filename
        #  File.open("#{RAILS_ROOT}/public/images/#{new_uploadfile}", "wb") do |f|  
        #    f.write(params[:language][:uploadfile].read)
        #  end
        #  new_uploadfile
        #else
        #  nil # default value
        #end
        #@language.save # save again

        flash[:notice] = print_words('language').capitalize_words + " \"#{@language.display_name}\" " + print_words('has been created')
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
    @language = Language.find_by_id(params[:id])
    
    # Check if item found and granted to be updated
    if @language.nil? || !granted_to(:update, @language) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    build_lookup_belongs
    
    elem_id = "language_offset_#{@language.id}"
    if params[:language]
      ## It's to help if you need to upload file/images, DB field name: image
      ## Check the form field and don't forget to set the multipart=true 
      ##
      #if params[:updateimage].blank?
      #  params[:language][:image] = @language.image
      #else
      #  new_image = SHA1.new(Time.now.to_s).to_s
      #  File.open("#{RAILS_ROOT}/public/images/#{new_image}.jpg", "wb") do |f|  
      #    f.write(params[:language][:image].read)
      #  end
      #  params[:language][:image] = "#{new_image}.jpg"
      #end
      if @language.update_attributes(params[:language])
        ## It's to help if you need to upload file/images, DB field name: uploadfile
        ## Check the form field and don't forget to set the multipart=true 
        ## And add an check box button to delete file, name: removefile
        ##
        #@language.uploadfile = 
        #  if params[:language][:uploadfile].class == StringIO then
        #    file_destroy(@language.uploadfile) unless @language.uploadfile.nil? rescue nil # delete if not default value
        #    new_uploadfile = SHA1.new(Time.now.to_s).to_s+params[:language][:uploadfile].original_filename
        #    File.open("#{RAILS_ROOT}/public/files/#{new_uploadfile}", "wb") do |f|
        #      f.write(params[:language][:uploadfile].read)
        #    end        
        #    new_uploadfile
        #  else
        #    if params[:removefile].blank?
        #      @language.uploadfile # no change
        #    else 
        #      file_destroy(@language.uploadfile) unless @language.uploadfile.nil? rescue nil # delete if not default value
        #      nil # default value
        #    end
        #  end
        #@language.save #save again

        flash[:notice] = print_words('language').capitalize_words + " \"#{@language.display_name}\" " + print_words('has been updated')
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
        page.replace_html "language_#{@language.id}", :partial => 'edit'
        page.visual_effect :highlight, "language_#{@language.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
        page << %Q{$("#{elem_id}").update(txt)}
      end
    end
  end

  # Show item
  def show
    @language = Language.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @language.nil?
    
    elem_id = "language_offset_#{@language.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "language_#{@language.id}", :partial => 'show'
      page.visual_effect :highlight, "language_#{@language.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Close Edit's form or Show
  def close
    @language = Language.find_by_id(params[:id])
    
    render :update do |page| page.redirect_to :action => 'index' end if @language.nil?
    
    elem_id = "language_offset_#{@language.id}"
    render :update do |page| 
      page << %Q{txt = $("#{elem_id}").innerHTML}
      page['message'].hide
      page.replace_html "message", ''
      page.replace_html "language_#{@language.id}", :partial => 'item', :locals => {:offset => ''}
      page.visual_effect :highlight, "language_#{@language.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FFFFFF'"      
      page << %Q{$("#{elem_id}").update(txt)}
    end
  end
  
  # Destroy item
  def destroy
    @language = Language.find_by_id(params[:id])
    
    # Check if item found and granted to be destroyed
    if @language.nil? || !granted_to(:delete, @language) then
      if request.xhr?
        render :update do |page| page.redirect_to :action => 'index' end
      else
        redirect_to :action => 'index'
      end
      return
    end
    
    language_display_name = @language.display_name
    if @language.destroy then
      ## It's to help if you need to upload file/images, DB field name: uploadfile
      ##
      #file_destroy(@language.uploadfile) unless @language.uploadfile.nil? rescue nil # delete if not default value
      render :update do |page| 
        page.visual_effect :fade, "language_#{@language.id}"
        page.delay 1 do
          page.remove 'language_'+params[:id]
        end
        page.replace_html 'message', ''
        page.insert_html :top,'message', print_words('language').capitalize_words + " \"#{language_display_name}\" " + print_words('has been deleted')
        page['message'].show
      end      
    else
      render :update do |page| 
        page.visual_effect :highlight, "language_#{@language.id}", :startcolor => "'#BFBFBF'", :endcolor => "'#FF5F5F'"
      end
    end
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
  
  # get field name to param key 
  helper_method :field_to_param
  def field_to_param(field_id)
    #@@field_to_param[field_id] 
    @@param_to_field.index(field_id) || field_id
  end
end
