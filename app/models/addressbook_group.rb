class AddressbookGroup < ActiveRecord::Base
  # primary_key :id
  validates_presence_of :name
  # validates_uniqueness_of :name
  validates_presence_of :user_id
  # validates_uniqueness_of :user_id
  
  validates_inclusion_of :public, :in => [true, false]
  
  belongs_to :user
  belongs_to :department
  
  has_many :addressbook_group_phones, :dependent => :destroy
  has_many :addressbook_contacts, :through => :addressbook_group_phones
  
  has_many :addressbook_group_users
  has_many :users, :through => :addressbook_group_users, :uniq => true
  
  # before_destroy :before_destroy
  
  # Ruport
  # acts_as_reportable
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute :name
  end

  def self.find_by_id(id)
    if id.class <= Array then
      find(:all, :conditions => ['id IN (?)', id])
    else
      find(:first, :conditions => {:id => id})
    end
  end
    
  def self.find_all
    find(:all, :order => '`name` ASC')
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
  
  # check if this item can be destroyed
  # the default is autmatoic has_one and has_many association, empty
  def can_destroyed?
=begin
    # list of associations to check (automatic)
    has_assocs = []
    self.class.reflections.each do |r_name, r|
      has_assocs << r_name if [:has_one, :has_many, :has_and_belongs_to_many].include? r.macro
    end

    # check for emptyness
    has_assocs.each do |r_name|
      next if [:addressbook_group_phones, :addressbook_contacts].include? r_name
      assoc = self.send(r_name)
      nothing = assoc.respond_to?('empty?') ? assoc.empty? : assoc.nil?
      return false unless nothing
    end
=end

    true
  end

  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end
end
