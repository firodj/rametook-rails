class SmsOutboxRecipient < ActiveRecord::Base
  
  #before_save :before_save
  
  has_many :modem_short_messages, :dependent => :destroy
  
  belongs_to :sms_outbox

  STATUS = %w(UNSENT SEND %\ SENT FAIL UNKNOWN)
  
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

  # as an array containing texts and values
  def self.find_all_for_select_option(blank = nil)
    select_option(find_all, blank)    
  end
  
  def self.select_option(objects, blank = nil)
    options = objects.map { |e| [e.display_name, e.id] }
    options.unshift([blank,'']) unless blank.nil?
    options
  end
  
  def self.write_sms(number, message, sms_outbox, options = {})
    time_now = sms_outbox ? sms_outbox.created_at : Time.now
    
    recipient = self.create(
      :number => number,
      :sms_outbox_id => (sms_outbox ? sms_outbox.id : nil),
      :removed => false
    )
      
    # for parital > 1 sms
    # modem device, user->message content->modem routing rules
    partial_message = message
    recipient.modem_short_messages.create(
      :status => 'UNSENT',
      :number => number,
      :check_time => time_now,
      :message => partial_message
    )

    # not here
    # recipient.status = recipient.computed_status
    # recipient.save!
    
    recipient
  end
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute :number
  end

  def cancel_sms
    ok = 0
    self.modem_short_messages.each { |short_message| ok += 1 if short_message.request_to_cancel }

    if ok > 0 then
      self.sms_outbox.update_attribute(:status_invalid, true) unless self.sms_outbox.status_invalid
      true
    end
  end

  # remove
  # TODO: should check if sms can be destroyed?
  def remove_sms
    cancel_sms
    if not self.removed and can_destroyed? then
      self.removed = true
      self.removed_at = Time.now
      self.save!
      
      self.sms_outbox.update_attribute(:status_invalid, true) unless self.sms_outbox.status_invalid
      true
    end
  end
  
  def resend_sms
    return false if self.removed
    
    ok = 0
    self.modem_short_messages.each { |short_message| ok += 1 if short_message.request_to_resend }
    
    if ok > 0 then
      self.sms_outbox.update_attribute(:status_invalid, true) unless self.sms_outbox.status_invalid
      true
    end
  end
  
  def computed_status
    if self.modem_short_messages.empty? then
      'UNKNOWN'
    else
      sent_status = 0
      fail_status = 0
      unsent_status = 0
    
      self.modem_short_messages.each do |sm| 
        if sm.status_is_sent? then
          sent_status += 1
        elsif sm.status_is_fail? then
          fail_status += 1
        elsif sm.status_is_unsent? then
          unsent_status += 1
        end
      end
      
      if unsent_status > 0 then
        'UNSENT'
      elsif sent_status > 0 then
        sent_status == self.modem_short_messages.size ?
          'SENT' :
          "%6.2f%% SENT" % (sent_status * 100 / self.modem_short_messages.size)
      elsif fail_status > 0 then
        'FAIL'
      else
        'SEND'
      end
    end
  end
  
  # check if this item can be destroyed
  # the default is autmatoic has_one and has_many association, empty
  def can_destroyed?
    return false if self.modem_short_messages.any? { |short_message| not short_message.can_destroyed? }
    true
  end

  def status(refresh = false)
    update_attribute(:status, computed_status) if refresh
    self[:status]
  end
    
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
    end
    
    def before_save
    end
end
