module Rametook
module SmsInboxProcessor

  def process
    return false if self.has_processed
    self.processed_at = Time.now
    self.processing_status = nil
=begin    
    
    unless process_for_message_delivered then
      if process_for_detect_contact_number then
        process_for_autoforward_to_operator
      else
        process_for_autoreply_to_public
      end
    end
=end
    self.has_processed = true
    save!
  end
  
  def process_for_message_delivered
    if self.message =~ /^Message (Sent Success|Pending|Sent Failed)/ then
      self.removed = true
      self.removed_at = Time.now
      self.processing_status = 'message_delivered'
      return true
    end
  end
  
  def process_for_detect_contact_number
    @phone = AddressbookPhone.search_by_number( self.number, :country_code => '62' ).first
  end
  
  def process_for_autoforward_to_operator
    o_contact = @phone.addressbook_contact
    o_numbers = []
    o_contact.addressbook_groups.each do |group|
      # collect group's operators contact
      group.addressbook_group_users.each { |gp|
        next unless gp.operator
        next unless gp.user.business_contact
        o_numbers += gp.user.business_contact.addressbook_phones.map(&:number)
      }
    end
    
    unless o_numbers.empty? then
      # reformating message if needed
      o_message = SmsReply.reply_with_custom(self.message, 
        { :header => 'autoforward_to_operator', 
          :header_tags => {:number => @phone.number, :contact => o_contact.display_name},
          :footer => 'autoforward_to_operator', 
          :footer_tags => {:number => @phone.number, :contact => o_contact.display_name}
        }
      )
      
      if o_sms_outbox = SmsOutbox.compose(o_message, o_numbers, :from_inbox => self, :redirect_as => 'forward') then
        o_sms_outbox.resend_all
        self.processing_status = 'autoforward_to_operator'
      else
        self.processing_status = 'autoforward_to_operator:composing_failed'
      end  
    else
      self.processing_status = 'autoforward_to_operator:numbers_empty'
    end
  end
  
  def process_for_autoreply_to_public
    # load message from temlpate
    o_message = SmsReply.reply_message('comment','ok',{'text' => self.message.truncate(60)},{:header => 'comment', :footer => 'comment'})
    if o_sms_outbox = SmsOutbox.compose(o_message, self.number, :from_inbox => self, :redirect_as => 'reply') then
      o_sms_outbox.resend_all
      self.processing_status = 'autoreply_to_public'
    else
      self.processing_status = 'autoreply_to_public:composing_failed'
    end
  end
  
end
end
