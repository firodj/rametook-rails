class SmsKeywordProcessor
  attr_reader :hash_sm_reply
  attr_reader :hash_sm
  attr_reader :logs
  attr_reader :time_now
  
  def self.number(str)
    number = (str || '').strip
    if !number.empty? && number.grep(/[^0-9\+]/).empty? then
      if number[0].chr == '+' then #+62xxx -> 0xxx
        number = '0' + number[3..-1]
      elsif number[0].chr != '0' && number.length > 7 then #62xxx -> 0xxx :FIXME:
        number = '0' + number[2..-1]
      end
    end
    number
  end
  
  def self.process(hash_sm, pretend = nil)
    sms_keywd_proc = self.new(hash_sm, pretend)
    return sms_keywd_proc unless sms_keywd_proc.parse.nil?
  end

  def self.format_help(str, tags = {})
    #data = []
    str ||= ''
    html = '<dl>'
    str.split("\n").each { |line|
      term, definitions = line.scan(/^(.*?)\:\s+(.*)$/)[0]
      next if term.nil?
      scrip = term[-1,1] == ':'
      term = term + (scrip ? '' : ':')
      html << "<dt>#{term}</dt>"
      definits = []
      definitions.split(" . ").each { |definit|
        definits << self.replace_tags(definit, tags)
      }
      html << '<dd'
      html << ' class="sms_keyword_script"' if scrip
      html << '>' + definits.join('<br />') + '</dd>'
      #data << [term, definits]
    }
    html << '</dl>'
  end

  def self.replace_tags(str, tags = {})        
    str.gsub(/\<[A-Za-z0-9_\-]+\>/im) { |match|
      v = match[1..-2].downcase
      tags[v].nil? ? match : tags[v]
    }
  end

  def self.help(function)    
    sms_keyword = SmsKeyword.find(:first, :conditions => {:function => function})
    return nil if sms_keyword.nil?
    
    tags = {'keyword' => sms_keyword.code}
    tags = send('help_' + function, tags) if methods.include?('help_' + function)
    SmsKeywordProcessor.format_help sms_keyword.help_info, tags    
  end

  def initialize(hash_sm = {}, pretend = nil)
    @hash_sm = hash_sm
    @logs = []
    @pretend = pretend
  end
  
  def parse()
    return nil if @hash_sm.empty?
    @time_now = Time.now
    @hash_sm['message'] ||= ''
    @hash_sm['number'] = SmsKeywordProcessor.number(@hash_sm['number'] || '')
        
    @params = @hash_sm['message'].strip.scan(/[^\s]+\s*/im)
    @keywd  = @params[0]

    return nil if @keywd.nil?
    @keywd = @keywd.strip.upcase
    @sms_keyword = SmsKeyword.find(:first, :conditions => {:code => @keywd}) 
    return nil if @sms_keyword.nil? || @sms_keyword.function.nil?            
    return nil if !methods.include?('do_' + @sms_keyword.function)
        
    @logs << "Keyword: #{@keywd} [" + @time_now.strftime("%d/%m/%Y %H:%M") + "]"
    @tags   = {}
    @hash_sm_reply = {}
    timeout = @time_now < @sms_keyword.active_since || @sms_keyword.active_until < @time_now
    @logs << (timeout ? 'Blocked! Time: ' : 'Accept! Time: ') + 
             @sms_keyword.active_since.strftime("%d/%m/%Y %H:%M") + " -- " +
             @sms_keyword.active_until.strftime("%d/%m/%Y %H:%M")
    @hash_sm_reply = reply( send('do_' + @sms_keyword.function) ) unless timeout

    return true
  end
  
  def reply(action)
    @sms_reply = SmsReply.find(:first, :conditions => {:function => @sms_keyword.function, :action => action})
    return {} if @sms_reply.nil? || @sms_reply.message.nil? || @sms_reply.message.empty?
    
    @sms_reply_header = SmsReply.find(:first, :conditions => {:function => 'header'}) 
    header = @sms_reply_header.nil? ? '' : (@sms_reply_header.message || '') 
    
    message = SmsKeywordProcessor.replace_tags(@sms_reply.message, @tags)

    @logs << "Reply: #{message}."

    message = header + ' ' + message if !header.empty? && !message.empty?    
    return {'number' => @hash_sm['number'], 'message' => message}
  end
end


