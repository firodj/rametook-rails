# This file is a candidate for a part of Rametook 0.4

class SmsKeyword < ActiveRecord::Base
  validates_uniqueness_of :code, :case_sensitive => false
  validates_presence_of :code
  validates_format_of :code, :with => /\A[A-Z0-9]+\Z/
  
  def find_by_code(name)
    find(:first, :conditions => {:code => name})
  end
end
