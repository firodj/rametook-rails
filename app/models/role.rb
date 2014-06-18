class Role < ActiveRecord::Base
  # primary_key :id
  validates_presence_of   :title
  validates_uniqueness_of :title  
  validates_presence_of   :description
  before_destroy          :before_destroy
  has_and_belongs_to_many :users
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute(:title).humanize
  end

  def self.find_all
    find(:all, :order => 'title ASC')
  end
  
  def self.find_by_id(id)
    if id.class <= Array then
      find(:all, :conditions => ['id IN (?)', id])
    else
      find(:first, :conditions => {:id => id})
    end
  end
  
  def self.find_by_title(title)
    find(:first, :conditions => {:title => title})
  end
  
  def can_destroyed?
    # superadmin role can't destroyed
    return false if self.title == 'superadmin'
    
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

    true
  end
  
  private
    def before_destroy
      can_destroyed?
    end
end
