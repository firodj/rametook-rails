class SmsOutbox < ActiveRecord::Base
  has_many :sms_outbox_recipients, :dependent => :destroy
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_user_id'
  
  belongs_to :from_outbox, :class_name => 'SmsOutbox', :foreign_key => 'redirect_from_sms_outbox_id'
  belongs_to :from_inbox,  :class_name => 'SmsInbox',  :foreign_key => 'redirect_from_sms_inbox_id'
  has_many :to_outboxes,   :class_name => 'SmsOutbox', :foreign_key => 'redirect_from_sms_outbox_id'
  
  def self.find_by_id(id)
    if id.class <= Array then
      find(:all, :conditions => ['id IN (?)', id])
    else
      find(:first, :conditions => {:id => id})
    end
  end
    
  def self.find_all
    find(:all, :order => '`id` ASC')
  end

  # :header => header
  # :footer => footer
  # :user_id => created_by_user_id
  def self.compose(message = '', numbers = [], options = {})
    return if message.blank? or numbers.blank?
    
    time_now = Time.now
    
    full_message = "#{options[:header]}#{message}#{options[:footer]}"
    
    sms_outbox = self.create(:message => full_message, 
      :created_at => time_now,
      :created_by_user_id => options[:user_id],
      :removed => false, :status_invalid => true,
      :redirect_as => options[:redirect_as],
      :from_outbox => options[:from_outbox],
      :from_inbox => options[:from_inbox]
    )
        
    numbers.each { |number| recipient = SmsOutboxRecipient.write_sms(number, full_message, sms_outbox ) }
    
    sms_outbox
  end
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute(:message).truncate(40)
  end
  
  # return computed grouped status
  def computed_status(refresh = false)
    sent_status = 0
    fail_status = 0
    unsent_status = 0
    
    self.sms_outbox_recipients.each do |recipient| 
      if recipient.status(refresh) == 'SENT' then
        sent_status   += 1
      elsif recipient.status =~ /%\ SENT$/ then
        sent_status   += recipient.status.to_f / 100
      elsif recipient.status == 'FAIL' then
        fail_status   += 1
      elsif recipient.status == 'UNSENT' then
        unsent_status += 1
      end
    end
    
    if unsent_status > 0 then
      'UNSENT'
    elsif sent_status > 0 then
      sent_status == self.sms_outbox_recipients.size ?
        'SENT' :
        "%6.2f%% SENT" % (sent_status * 100 / self.sms_outbox_recipients.size)
    elsif fail_status > 0 then
      'FAIL'
    else
      'SEND'
    end
  end
  
  def cancel_all
    ok = 0
    self.sms_outbox_recipients.each { |recipient| ok += 1 if recipient.cancel_sms }
    if ok > 0 then
      self.reload
      true
    end
  end
  
  def resend_all
    ok = 0
    self.sms_outbox_recipients.each { |recipient| ok += 1 if recipient.resend_sms }
    self.reload
    if ok > 0 then
      self.reload
      true
    end
  end

  def remove_all
    ok = 0
    
    cancel_all
    if not self.removed and can_destroyed? then
      self.sms_outbox_recipients.each { |recipient| ok += 1 if recipient.remove_sms }
      update_attribute(:removed, true)
    end
    
    ok > 0
  end
    
  def numbers
    self.sms_outbox_recipients.map(&:number)
  end
  
  def status(refresh = false)
    refresh ||= self.status_invalid
    if refresh then
      self.status = computed_status(true)
      self.status_invalid = false
      self.save!
    end
    
    self[:status]
  end
  
  def can_destroyed?
    return false if self.sms_outbox_recipients.any? { |recipient| not recipient.can_destroyed? }
    true
  end
end
