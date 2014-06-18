class SettingController < ApplicationController
  before_filter :login_required
  access_control :DEFAULT => 'superadmin'
  verify :method => :post, :only => :update, :redirect_to => { :action => 'update' }
  def index
    edit
    render :action => 'edit'
  end
  
  def edit
    @settings = Setting.find(:all).sort do |a,b| 
      if a.plugins == 'general' then
        -1
      elsif b.plugins == 'general' then
        +1
      else
        a.plugins <=> b.plugins
      end
    end
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => ['update'],
         :redirect_to => { :action => 'edit' }

  def update
    params[:settings].each do |k, v|
      Setting.update(k, {:value => v})
    end
    session[:settings] = nil
    
    flash[:notice] = print_words('setting').capitalize_words + ' ' + print_words('has been updated')
    redirect_to :action => 'edit'
  end
  
end
