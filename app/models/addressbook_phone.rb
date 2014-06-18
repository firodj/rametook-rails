class AddressbookPhone < ActiveRecord::Base

  NAME = ['Phone', 'Mobile', 'Fax']

  validates_presence_of :name
  validates_presence_of :number
  validates_presence_of :display_number
  
  belongs_to :addressbook_contact
  
  acts_as_list :scope => :addressbook_contact_id
  
  def display_number=(number)
    self.number = number
  end
  
  def number=(number)
    if number then
      self[:display_number] = number.gsub(/[^0-9\*\#\-\(\)\ \+]+/, ' ').strip
      self[:number] = self[:display_number].gsub(/[^0-9\*\#]+/, '')
    else
      self[:display_number] = nil
      self[:number] = nil
    end
  end
  
  
  # TODO:
  # http://en.wikipedia.org/wiki/Telephone_numbering_plan
  # http://en.wikipedia.org/wiki/List_of_country_calling_codes
  def self.other_number_forms(number, options = {})
    numbers = []
    return numbers if number =~ /[^0-9\*\#]+/
    
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
  
  def self.search_by_number(number, options = {})
    numbers = other_number_forms number, :country_code => options.delete(:country_code)
    addressbook_phones = []
    return addressbook_phones if numbers.empty?
    
    find_options = {}
    find_options[:conditions] = ["number IN (#{['?'] * numbers.size * ','})", *numbers]
    
    self.find(:all, find_options)
  end
    
end
