class SmsSendController < ApplicationController
  before_filter :login_required
                # :only => [:new, :edit, :destroy]
  verify  :xhr => true,
          :only => [:update_addressbook_result]
                
  def index
    #@addressbook_filters = ['private addressbook contact', 'public addressbook contact', 'private addressbook group', 'public addressbook group'].map { |e| [ print_words(e).capitalize_words, e] }
    #@addressbook_filters.unshift(['',''])
    # @departments = Department.find_all_for_select_option('*') rescue [['ERROR','']]
    
    @sms_templates = SmsTemplate.find_all_for_select_option('')
    
    build_message_parts
  end
  
  hide_action :build_message_parts
  def build_message_parts
    @message_signature = "\n--\n#{self.current_user.display_name.truncate(24)}"
  end
  
  def update_addressbook_result
    contacts = []
    
    unless params[:addressbook].blank? then
      is_public = !(params[:addressbook] =~ /public/).nil?
      is_group  = !(params[:addressbook] =~ /group/).nil?
      
      if is_group then
        conditions = {}
        conditions[:public] = is_public
        conditions[:user_id] = self.current_user.id if !is_public
        conditions[:department_id] = params[:department_id] if !params[:department_id].blank?
        
        AddressbookGroup.find(:all, 
          #:conditions => conditions, 
          :order => 'name').each { |group|
           
          #next if is_public && !group.department_id.nil? && e.department_id != self.current_user.department_id && !permit?('superadmin')
          
          contacts << { :type => 'group', :id => group.id, 
            :title => group.display_name, 
            :info => group.addressbook_group_phones.size }
        }
      else # is_contact
        conditions = {}
        conditions[:public] = is_public
        conditions[:user_id] = self.current_user.id if !is_public
        conditions[:department_id] = params[:department_id] if !params[:department_id].blank?
        
        AddressbookContact.find(:all, 
          #:conditions => conditions, 
          :order => 'name').each { |contact| 
          
          #contact.addressbook_phones.each { |phone|
          #    contacts << [phone.id, 'phone', contact.display_name, phone.display_number]
          #}
          
          contacts << { :type => 'contact', :id => contact.id, 
            :title => contact.display_name,
            :info => contact.addressbook_phones.size }
        }
      end
    end
    render :json => contacts.to_json
  end
  
  # contact_id => addressbook_group_id
  def update_addressbook_group
    phones = []
    AddressbookGroup.find_by_id(params[:contact_id]).addressbook_group_phones.each { |e|
      phones << {:id => e.addressbook_phone.id, 
        :type => e.addressbook_phone.name,
        :contact => e.addressbook_phone.addressbook_contact.display_name, 
        :info => e.addressbook_phone.display_number,
        :value => e.addressbook_phone.number }
    }
    render :json => phones.to_json
  end
  
   # contact_id => addressbook_contact_id
  def update_addressbook_contact
    phones = []
    AddressbookContact.find_by_id(params[:contact_id]).addressbook_phones.each { |e|
      phones << {:id => e.id, 
        :type => e.name,
        :contact => e.addressbook_contact.display_name, 
        :info => e.display_number,
        :value => e.number }
    }
    render :json => phones.to_json
  end
  
  def send_to_outbox
    build_message_parts
    
=begin
    numbers = []
    params[:recipients].each { |recipient|
      contact_id, field_id = recipient.split(',')
      if field_id == 'direct' then
        numbers << contact_id
      else
        contact_id = contact_id.to_i
        contact = AddressbookContact.find_by_id(contact_id)
        numbers << contact[field_id] if contact && contact[field_id]
      end
    } if !params[:recipients].blank?
=end 
    #numbers << params[:direct_number] if !params[:direct_number].blank?
    
    sms_outbox = SmsOutbox.compose(params[:sms_send_message],
        params[:recipients],
        :user_id => @current_user.id,
        :user_group_id => @current_user.department_id,
        :footer => @message_signature)
        
    if sms_outbox then
      sms_outbox.resend_all    
      redirect_to :controller => 'sms_outboxes', :action => 'list'
    else
      flash[:notice] = "Failed to Send SMS"
      index
      render :action => 'index'
    end
  end
  
  def select_sms_template
    sms_tempalte = SmsTemplate.find_by_id(params[:sms_template_id])
    render :update do |page|
      page['sms_send_message'].value = sms_tempalte.template if sms_tempalte
      page['sms_send_message'].onkeyup
    end
  end
  
  def send_from_forward
    @sms_outbox = SmsOutbox.find(params[:id])
    params[:sms_send_message] = @sms_outbox.message
    # params[:recipients] = @sms_outbox.numbers
    index
    render :action => 'index'
  end
  
  def send_from_reply
    @sms_inbox = SmsInbox.find(params[:id])
    # params[:sms_send_message] = @sms_inbox.message
    params[:recipients] = [@sms_inbox.number]
    index
    render :action => 'index'    
  end
  
  def keyword_simulation
  end
  
  def smstry  
    log = message = number = nil
    msg = params[:sms_keyword_then_reply][:message].strip    
    nmb = params[:sms_keyword_then_reply][:number].strip

    pretend = true
    restrict_to 'affect_trysms | superadmin' do
      pretend = false if params[:sms_keyword_then_reply][:affected] == '1'
    end
    if nmb.empty? || msg.empty? then
      render :update do |page|
        page.visual_effect :highlight, 'sms_keyword_then_reply_number'  if nmb.empty?
  	    page.visual_effect :highlight, 'sms_keyword_then_reply_message' if msg.empty?
  	  end
    else
      message = number = log = ''
	    begin
	      sms_keywd_proc = DefaultSmsKeyword.process({'number' => nmb,
	        'message' => msg}, pretend)
	    rescue Exception => e
	      log = "Exception: #{e.message}.<br />\n" + e.backtrace.join("<br />\n")
	    else
	      if !sms_keywd_proc.nil? then
	        message = sms_keywd_proc.hash_sm_reply['message']
	        number  = sms_keywd_proc.hash_sm_reply['number']
	        logs = sms_keywd_proc.logs
	        logs << "Message length: #{message.length}" if !message.nil?
	        logs << (pretend ? "Pretend" : "Affected")
	        log  = logs.join("\n")
	        SmsLog.create(:status => 'INBOX-TRY', :check_time => sms_keywd_proc.time_now,
  			    :number => nmb, :message => msg, :process => log) if !pretend  			    
     			SmsLog.create(:status => 'OUTBOX-TRY', :check_time => sms_keywd_proc.time_now,
    			  :number => number, :message => message) if !pretend && !sms_keywd_proc.hash_sm_reply.empty?
	      end
	    end

	    render :update do |page|
	      page.replace_html 'reply_number', ERB::Util.h(number)
	      page.replace_html 'reply_message', ERB::Util.h(message)
	      page.visual_effect :highlight, 'reply_number' 
	      page.visual_effect :highlight, 'reply_message' 
	      page.replace_html 'process_log', log.gsub("\n","<br />\n")
	    end
	    
    end
  end  
  
  def update_progress
    progress
    render :partial => 'update_progress'
    #render :layout => false
  end
end
