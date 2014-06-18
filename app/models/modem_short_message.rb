class ModemShortMessage < ActiveRecord::Base
  belongs_to :modem_device
  has_many   :modem_pdu_logs
    
  belongs_to :sms_inbox
  belongs_to :sms_outbox_recipient
  
  # status value (may be not saved on db, but used on the fly)
  # INBOX
  # OUTBOX
  # PROCESS
  # SENDING
  # WAITING
  # UNSENT
  # RESEND
  # SENT
  # FAIL
  
  STATUS = %w(UNSENT SEND SEND-PROCESS SEND-ERROR SENT SENT-FAILED SENT-DELIVERED RECEIVED RECEIVED-PARTED)
  # UNSENT
  # SEND -> SEND-PROCESS -> SENT -> SENT-FAILED
  #                              -> SENT-DELIVERED
  #                      -> SEND-ERROR
  # RECEIVED | RECEIVED-PARTED
  
  # Convert attributes to hash
  def to_hash
    hash = {}
    for column_name in ModemShortMessage.column_names
      hash[column_name] = self.send(column_name)
    end
    hash
  end
  
  # Set attributes from hash
  def from_hash( hash)
    for column_name in ModemShortMessage.column_names
      self.send(column_name + '=', hash[column_name]) if !hash[column_name].nil?
    end
  end
  
  def self.find_by_status(status)
    find(:all, :conditions => {:status => status})
  end
  
  def self.find_by_id(id)
    find(:first, :conditions => {:id => id})
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

  # display_name 
  # default item name to display
  def display_name
    read_attribute :id
  end

  # check if this item can be destroyed
  # the default is autmatoic has_one and has_many association, empty
  def can_destroyed?
    self.status != 'SEND-PROCESS'
  end
  
  # SENT included bcoz this may falls to SENT-FAILED, to avoid auto-resend
  def can_canceled?
    %w(SEND SEND-PROCESS SEND-ERROR SENT SENT-FAILED).include?(self.status)
  end
  
  def can_resent?
    %w(UNSENT SEND-ERROR SENT-FAILED).include?(self.status)
  end
  
  def status_is_sent?
    %w(SENT SENT-DELIVERED).include?(self.status)
  end
  
  def status_is_fail?
    %w(SEND-ERROR SENT-FAILED).include?(self.status)
  end
  
  def status_is_unsent?
    self.status == 'UNSENT'
  end
  
  def mark_status_invalid!
    return unless self.sms_outbox_recipient
    return if self.sms_outbox_recipient.sms_outbox.status_invalid
    self.sms_outbox_recipient.sms_outbox.update_attribute(:status_invalid, true)
  end
  
  def request_to_cancel
    lock!
    if not self.cancel_sending and can_canceled? then
      self.status = 'UNSENT' if self.status == 'SEND'
      self.cancel_sending = true
      c = true
    end
    save! && c
  end
  
  def request_to_resend
    lock!
    if can_resent? then
      self.status = 'SEND'
      self.cancel_sending = false
      c = true
    end
    save! && c
  end
  
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end 
end
