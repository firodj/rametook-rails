class ModemErrorMessage < ActiveRecord::Base  
  @@modem_error_messages = {'phone_failure' => {}, 'access_failure' => {}}
  
  def self.init_constants
    find(:all).each { |e|
      @@modem_error_messages[e.err_type] ||= {}
      @@modem_error_messages[e.err_type][e.code] = e
    }    
    @@modem_error_messages.freeze
  end
  
  def self.get_error_message_for(type, code)
    @@modem_error_messages[type][code]
  end
  
  def self.find_by_type_and_code(type, code)
    find(:first, :conditions => {:err_type => type, :code => code})
  end
end
