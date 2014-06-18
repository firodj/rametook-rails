class ApplicationController < ActionController::Base
  require 'sha1'
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => Setting.find_by_name('site email').value + '_session_id'  
  include AuthenticatedSystem
  include Toombila::ActionControllerRescue

  # layout 'toombila_rametook'
  #layout 'toombila_sms_dprd'
  
  sliding_session_timeout 30.minutes
  
  # web configuration/setting retriever
  helper_method :setting_info
  def setting_info(name)
    session[:settings] = {} unless session[:settings]
    unless session[:settings][name] then
      setting_found = Setting.find_by_name(name)
      session[:settings][name] = setting_found.value if setting_found
    end
    session[:settings][name]
  end

  # words retriever
  helper_method :print_words
  def print_words(words)
      # developer = (logged_in? && permit?('developer') && params.has_key?( :lang_dev ))
      session[:words] = {} unless session[:words]
      unless session[:words][words] then
        lang = setting_info('language')
        lang = session[:settings]['language'] = 'en' if lang.nil? || lang.empty?
        # lang = developer ? (params[:lang_dev] || setting_info('language')) : setting_info('language')
        trans_words = Language.find(:first, :conditions => ["name = ? and language = ?", words, lang])
        session[:words][words] = trans_words.value if trans_words
      end
      # if developer then
      #   return params[:lang_dev].nil? ? ('{' + words + '}') :
      #     (session[:words][words].nil? ? ('{' + words + '}') : session[:words][words])
      # end
      session[:words][words].nil? ? words : session[:words][words]
  end  
  
  # sentence-words retriever, using @{...}
  helper_method :trans_text
  def trans_text(sentence)
    sentence.gsub(/\@\{.+?\}/) { |x| print_words(x[2..-2]) }
  end
  
  # redirect_to_index
  # Redirect to index with or without flash message
  def redirect_to_index(msg = nil)
    flash[:message] = msg unless msg.nil? 
    redirect_to :action => 'index', :id => params[:id]
  end
  
  # This is an example howto use ActionView helper on controller
  #def help
  #  Helper.instance
  #end
  #
  #class Helper
  #  include Singleton
  #  include ActionView::Helpers::TextHelper
  #  include ActionView::Helpers::TagHelper
  #  # add other helpers
  #end    

  protected

  def permission_denied
    flash[:error] = print_words('not enough access level').capitalize
    redirect_to :controller => 'account', :action => 'index'
  end

  def file_destroy(img)
    File.delete("#{RAILS_ROOT}/public/images/#{img}") if FileTest.exist?("#{RAILS_ROOT}/public/images/#{img}")
  end
      
  # Rails 2.0 deprecated method handler
  # Always comment it! overwritten by AuthenticatedSystem
  #def redirect_back_or_default(path)
  #  redirect_to :back
  #rescue ActionController::RedirectBackError
  #  redirect_to path
  #end  
    
  #TRANSISTIONAL --deprecated--
  def get_search_filters(name = controller_name.to_sym)
    if session[:filters] && session[:filters][name] then
      session[:filters][name] 
    else
      {}
    end
  end
  
  def set_search_filters(filters, name = controller_name.to_sym)
    session[:filters] = {} unless session[:filters]
    if filters.nil? or filters.empty? then
      session[:filters].delete(name)
    else
      session[:filters][name] = filters
    end
  end
  
  def update_search_filters(filters, name = controller_name.to_sym)
    return if filters.nil? or filters.empty?
    search_filters = get_search_filters(name)
    filters.each { |k,v| if v == :delete then search_filters.delete(k) else search_filters[k] = v end }
    set_search_filters search_filters.update(filters), name
  end
  #END OF TRANSISIONAL --- remove it!
end
