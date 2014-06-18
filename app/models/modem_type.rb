class ModemType < ActiveRecord::Base
  SmsModes = %w(PDU TEXT HEX)
  
  # primary_key :id
  validates_presence_of :name
  # validates_uniqueness_of :name
  validates_inclusion_of :sms_mode, :in => SmsModes
  #validates_presence_of :init_command
  # validates_uniqueness_of :init_command

  has_and_belongs_to_many :modem_at_commands
  
  has_many :modem_devices
    
  # before_destroy :before_destroy
  
  # Ruport
  # acts_as_reportable  
  
  # display_name 
  # default item name to display
  def display_name
    read_attribute :name
  end

  def self.find_by_id(id)
    find(:first, :conditions => {:id => id})
  end
  
  def self.find_by_name_like(name)
    find(:first, :conditions => ['name LIKE ?',  name])
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
  
  def self.detect_all(identifier)
    identifier_clean = identifier.gsub(/[^a-z0-9]+/im, ' ')
    
    find(:all, 
         :conditions => ["`detect_regexp` > ? AND ? REGEXP(`detect_regexp`)", 
                         '', 
                         identifier_clean
                        ]
        )
  end
      
  def self.detect_first(identifier)
    detect_all(identifier).first
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

  def detect_pattern=(string)
    write_attribute(:detect_pattern, string)
    set_detect_regexp
  end
  
  def set_detect_regexp
    string = read_attribute(:detect_pattern)
    regexpstr = string ? string.gsub(/\s+\|\s+/im,'|').gsub(/\s+/im,"[[:space:]]+").gsub(/\*+/im,".*") : nil
    # regexpstr = "(#{regexpstr})" if regexpstr =~ /\|/im
    write_attribute(:detect_regexp, regexpstr)
  end
 
  def export 
    hash = self.attributes.dup
    hash.delete('id')
    hash.delete('detect_regexp')
    hash['modem_at_commands'] = []
    self.modem_at_commands.each { |at_command|
      hash_at = at_command.attributes.dup
      hash_at.delete('id')
      hash_at.delete('modem_type_id')
      hash_at.delete('modem_at_command_id')
      
      hash['modem_at_commands'] << hash_at
    }
    "# Toombila Rametook Modem Type\n# Exported at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\n" + hash.to_yaml
  end
  
  def self.import(yaml)
    return unless yaml =~ /\# Toombila Rametook Modem Type/
    hash = YAML.load(yaml)
    hash_at = hash.delete('modem_at_commands')
    modem_type = new(hash)
    modem_type.set_detect_regexp
    modem_type.save!
    
    hash_at.each { |at_cmd|
      modem_type.modem_at_commands << ModemAtCommand.create!(at_cmd)
    }
    
    return modem_type
  end
  
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end
end
