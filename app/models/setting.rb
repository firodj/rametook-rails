class Setting < ActiveRecord::Base
  # primary_key :id
  validates_presence_of :name
  validates_uniqueness_of :name
  
  # find setting by name
  def self.find_by_name(name)
    Setting.find(:first, :conditions => {:name => name})
  end
end
