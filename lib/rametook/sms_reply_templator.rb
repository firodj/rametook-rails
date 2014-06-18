module Rametook
module SmsReplyTemplator

  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:include, InstanceMethods)
  end
  
  module InstanceMethods
    def format_message(tag_values = {})
      tag_matches = self.tags ? self.tags.split(',') : []
      self[:message].gsub(/\<[A-Za-z0-9_\-]+\>/im) do |match|
        tag = match[1..-2].downcase # excluding < and > characters
        tag_matches.index(tag) ? tag_values[tag] || tag_values[tag.to_sym] : match
      end
    end
  end
  
  module ClassMethods
    def find_by_function_and_action(function, action, active = true)
      find(:first, :conditions => ["function #{function ? '=' : 'IS'} ? AND action #{action ? '=' : 'IS'} ? AND active = ?", function, action, active])
    end
    
    def reply_body(function, action, tags = {})
      sms_reply = find_by_function_and_action(function, action)
      return if sms_reply.nil? or sms_reply.message.blank?
      sms_reply.format_message(tags)
    end
    
    # action = nil use default action
    # action = false disable
    def reply_header(action = nil, tags = {})
      reply_body('header', action, tags) unless action == false
    end
    
    # action = nil use default action
    # action = false disable
    def reply_footer(action = nil, tags = {})
      reply_body('footer', action, tags) unless action == false
    end
    
    def reply_message(function, action, tags = {}, options = {})
      header = reply_header(options[:header], options[:header_tags] || {})
      body   = reply_body(function, action, tags)
      footer = reply_footer(options[:footer], options[:footer_tags] || {})
      
      message_parts = []
      message_parts << header if header
      message_parts << body
      message_parts << footer if footer
      message_parts.join(options[:separator] || "\n--\n")
    end
    
    def reply_with_custom(body, options = {})
      header = reply_header(options[:header], options[:header_tags] || {})
      footer = reply_footer(options[:footer], options[:footer_tags] || {})
      
      message_parts = []
      message_parts << header if header
      message_parts << body
      message_parts << footer if footer
      message_parts.join(options[:separator] || "\n--\n")
    end
  end
  
end
end
