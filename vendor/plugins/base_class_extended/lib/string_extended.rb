class String
  class TextHelper
    extend ActionView::Helpers::TextHelper
  end
  
  def capitalize_words
    #s = ''
    #self.scan(/(\s*)([^\s]+)(\s*)/) { |pre,w,post| s << pre << w.capitalize << post }
    #s
    self.gsub(/^[a-z]|[\s\.][a-z]/) { |a| a.upcase }
  end
  
  def excerpt(phrase, radius = 100, excerpt_string = "...")
    TextHelper.excerpt(self, phrase, radius, excerpt_string)   
  end
  
  def truncate(length = 30, truncate_string = "...")
    TextHelper.truncate(self, length, truncate_string).to_s
  end
    
  def word_wrap(line_width = 80)
    TextHelper.word_wrap(self, line_width)
  end
  
  # newline to HTML breakline, like PHP nl2br
  def nl_to_br
    gsub(/\r\n|\n/,"<br />")
  end
  
  # TODO:
  # http://en.wikipedia.org/wiki/Telephone_numbering_plan
  # http://en.wikipedia.org/wiki/List_of_country_calling_codes
  def phone_other_formats(options = {})
    numbers = []
    number = self
    return numbers if number =~ /[^0-9\*\#]+/i
    
    numbers << number
    
    if number.size > 5 then
      if number[0,1] == '0' then
        numbers << "#{options[:country_code]}#{number[1..-1]}" if options[:country_code]
      else
        options[:country_code] = number[0,2]
        numbers << "0#{number[2..-1]}"
      end
    end
    
    numbers
  end
end
