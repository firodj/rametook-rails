class SmsReportsController < ApplicationController
  before_filter :login_required
  
  def index
    params[:date] ||= Date.today.strftime('%Y-%m-%d')
  end
  
  def show
    if respond_to? params[:summary_by] then
      send params[:summary_by]
    else
      redirect_to :action => 'index'
    end 
  end
  
  def daily_count
    dt = params[:date].to_date
    
    # build query   
    inbox = Toombila::SummaryCalculations::Query.new SmsInbox, 
      :selects => {
        :inbox => 'COUNT(`id`)',
        #:monthly => 'MONTH(`received_time`)',
        :daily   => 'DAY(`received_time`)'},
      :groups => [:daily],
      :rollups => [:daily],
      :conditions => [
        'YEAR(`received_time`) = ? AND MONTH(`received_time`) = ?', 
        dt.year, dt.month ]
    inbox.execute(false)
    
    # build query   
    outbox = Toombila::SummaryCalculations::Query.new SmsOutbox, 
      :selects => {
        :outbox => 'COUNT(`id`)',
        #:monthly => 'MONTH(`received_time`)',
        :daily   => 'DAY(`sent_time`)'},
      :groups => [:daily],
      :rollups => [:daily],
      :conditions => [
        'YEAR(`received_time`) = ? AND MONTH(`received_time`) = ?', 
        dt.year, dt.month ],
      :share => inbox
    outbox.execute
    
    @results = outbox.results
    
    render :inline => "<%= debug @results %>"
  end
  
  def daily_log
    dt = params[:date].to_date
    
    SmsInbox.find :all, :conditions => [
      'YEAR(`received_time`) = ? AND MONTH(`received_time`) = ?', 
      dt.year, dt.month ]
    
    
  end
  
  
end
