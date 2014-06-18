class SmsInbox < ActiveRecord::Base
  include Rametook::SmsInboxProcessor
  
  has_many :modem_short_messages, :dependent => :destroy
  #before_save :before_save
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute :id
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
  
  def self.acquire_received_short_messages
    sms_inboxes = []
    time_now = Time.now
    ModemShortMessage.find(:all, 
      :conditions => ["status LIKE ? AND sms_inbox_id IS ?", 'RECEIVED%', nil]).each do |short_message|      
      if short_message.status == 'RECEIVED' then
        sms_inbox = create( :number => short_message.number, 
          :message => short_message.message,
          :sent_time => short_message.service_center_time,
          :received_time => time_now,
          :has_read => false,
          :removed => false,
          :has_processed => false,
          :partial_message => 1 )
        short_message.update_attribute(:sms_inbox_id, sms_inbox.id)  
        sms_inboxes << sms_inbox
      end
    end
    
    sms_inboxes
  end
  
  def self.process_unprocess_inbox
    sms_inboxes = []
    
    find(:all, :conditions => ['has_processed = ? AND removed = ?', false, false], :include => :modem_short_messages).each { |sms_inbox|
      next if sms_inbox.partial_message < sms_inbox.modem_short_messages.size
      sms_inboxes << sms_inbox if sms_inbox.process
    }
    sms_inboxes
  end
  
  # check if this item can be destroyed
  # the default is autmatoic has_one and has_many association, empty
  def can_destroyed?
    # return false unless self.modem_short_messages.any? { |short_message| %w(RECEIVED).include?(short_message.status) }
    
=begin
    # list of associations to check (automatic)
    has_assocs = []
    self.class.reflections.each do |r_name, r|
      has_assocs << r_name if [:has_one, :has_many, :has_and_belongs_to_many].include? r.macro
    end

    # check for emptyness
    has_assocs.each do |r_name|
      assoc = self.send(r_name)
      nothing = assoc.respond_to?('empty?') ? assoc.empty? : assoc.nil?
      return false unless nothing
    end
=end
    true
  end

  def filter
    contacts = AddressbookContact.whose_number( self.number ) 
    return if contacts.nil? || contacts.empty?
    
    contact = contacts.first[0]
    if inbox_filter = SmsInboxFilter.find(:first, :conditions => ['addressbook_contact_id = ? OR department_id = ?', contact.id, contact.department_id] ) then
      self.user_id = inbox_filter.user_id if inbox_filter.user_id
      self.user_group_id = inbox_filter.user_group_id if inbox_filter.user_group_id 
      return save
    end
  end
  
  def remove
    update_attributes(:removed => true, :removed_at => Time.now) unless self.removed    
  end
  
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end
    
    def before_save
      # self.removed ||= false
      # nil
    end
end
