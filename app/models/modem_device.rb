class ModemDevice < ActiveRecord::Base
  Parities = %w(NONE ODD EVEN)
  
  validates_presence_of :device
  validates_presence_of :baudrate
  validates_presence_of :databits
  validates_presence_of :stopbits  
  #validates_inclusion_of :parity, :in => Parities
  #validates_inclusion_of :active, :in => [false, true]
 
  belongs_to :modem_type
  
  # capabilities:
  #
  # read when listing
  # wait status report
  # dont care message ref
  # dont send
  #
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute :id
  end

  def self.find_by_id(id)
    find(:first, :conditions => {:id => id})
  end
    
  def self.find_all
    find(:all, :order => '`id` ASC')
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
  
  def capable_of(name)
    return unless self.capabilities
    
    unless @capable_of then
      @capable_of = {}
      self.capabilities.split(',').each { |capability|
        c_name, c_value = capability.split(':')
        c_name = c_name.strip.gsub(' ','_').to_sym
        @capable_of[c_name] = c_value ? c_value.strip : true
      }
    end
    
    @capable_of[name]
  end

  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end
end
