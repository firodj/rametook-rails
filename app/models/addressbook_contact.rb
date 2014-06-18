class AddressbookContact < ActiveRecord::Base
  
  DIRECTORY = 'public/images/'
  
  validates_presence_of :name
 
  validates_presence_of :user_id
  
  validates_inclusion_of :public, :in => [true, false]
  
  belongs_to :department
  belongs_to :user
  
  has_many :addressbook_group_phones, :dependent => :destroy
  has_many :addressbook_groups, :through => :addressbook_group_phones, :uniq => true
  has_many :addressbook_phones, :dependent => :destroy
  has_one :business_user, :class_name => 'User', :foreign_key => 'business_contact_id'
  
  # before_destroy :before_destroy
  after_save :process_image
  after_save :save_groups
  after_update :save_phones
  after_destroy :cleanup_image
  
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
  
  def self.whose_number(number, user_id = nil)
    numbers = number.phone_other_formats
    contacts = []
    return contacts if numbers.empty?
    
    number_sql = numbers.join("','")
    conditions = "(phone IN ('#{number_sql}') OR mobile1 IN ('#{number_sql}') OR mobile2 IN ('#{number_sql}'))"
    conditions += " AND (public = 1"
    conditions += " OR (user_id = #{user_id.to_i} AND public = 0)" if user_id
    conditions += ")"
    
    self.find(:all, :conditions => conditions).each { |contact|
        %w(phone mobile1 mobile2).each { |field|
          contacts << [ contact, field ] if numbers.include?(contact[field])
        }
    }
    contacts
  end
  
  # check if this item can be destroyed
  # the default is autmatoic has_one and has_many association, empty
  def can_destroyed?
    return !self.business_user
    # list of associations to check (automatic)
    #has_assocs = []
    #self.class.reflections.each do |r_name, r|
    #  has_assocs << r_name if [:has_one, :has_many, :has_and_belongs_to_many].include? r.macro
    #end
    
    # check for emptyness
    #has_assocs.each do |r_name|
    #  assoc = self.send(r_name)
    #  nothing = assoc.respond_to?('empty?') ? assoc.empty? : assoc.nil?
    #  return false unless nothing
    #end
     
    true
  end

  def update_groups(group_ids)
    group_ids ||= []
    groups_to_add = group_ids.dup
    groups_to_del = []
    self.addressbook_group_phones.each { |gp| 
      if group_ids.include?(gp.addressbook_group_id) then
        groups_to_add.delete(gp.addressbook_group_id)
      else
        groups_to_del << gp
      end
    }

    self.addressbook_group_phones.delete(groups_to_del)

    groups_to_add.each { |gid|
      %w(phone mobile1 mobile2).each { |f|
        self.addressbook_group_phones << AddressbookGroupPhone.new(:addressbook_group_id => gid, :field => f) unless attributes[f].blank?
      }
    }

    save
  end

  def migrate
    # self.addressbook_phones.clear
    
    %w(phone mobile1 mobile2).each do |f|
      number = attributes[f]
      adr_p = self.addressbook_phones.find(:first, :conditions => ['name = ?', f])
      
      if number.blank? then
        adr_p.destroy if adr_p
      else
        adr_p ||= AddressbookPhone.new(:name => f)
        adr_p.number = number
        #adr_p.display_number = adr_p.number
        self.addressbook_phones << adr_p
        
        if gp = self.addressbook_group_phones.find(:first, :conditions => ['field = ?', f]) then
          gp.addressbook_phone = adr_p
          gp.save
        end
      end
    end
  end

  def self.search_by_name(name)
    name = name.gsub(/\%/,'\%').strip.gsub(/\s+/,'%')
    self.find(:all, :conditions => ['name LIKE ?', "%#{name}%"])
  end

  # default image attachmet field is image
  # image must be a stream/file object (have original_filename method) to save it!,
  # image must be false to remove it!,
  # image must be nil if there's nothing to do with image
  def image=(image)
    @upload_image = image.respond_to?(:original_filename) || image == false ? image : nil
  end
  
  def new_phones_attributes=(phones_attributes)
    phones_attributes.each do |phone_attributes|
      self.addressbook_phones.build(phone_attributes)
    end
  end

  def existing_phones_attributes=(phones_attributes)
    self.addressbook_phones.reject(&:new_record?).each do |addressbook_phone|
      if phone_attributes = phones_attributes[addressbook_phone.id.to_s] then
        addressbook_phone.attributes = phone_attributes
      else
        self.addressbook_phones.delete(addressbook_phone)
      end
    end
  end
  
  def selecting_groups_attributes=(groups_attributes)
    groups_to_add = []
    groups_to_del = self.addressbook_groups.map(&:id)
    
    groups_attributes.each_pair { |group_id_s, attribs|
      if attribs['selected'].to_i > 0 then
        unless group_id = groups_to_del.delete(group_id_s.to_i) then
          groups_to_add << group_id_s.to_i
        end
      end
    }
    
    AddressbookGroup.find(groups_to_del).each { |group|
      self.addressbook_groups.delete(group)
    }
    
    groups_to_add.each { |group_id|
      self.addressbook_phones.each { |phone|
        self.addressbook_group_phones.build(
          :addressbook_group_id => group_id, 
          :addressbook_phone_id => phone.id
        )
      }
    }
  end
  
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def before_destroy
      # can_destroyed?
    end
    
    def process_image
      unless @upload_image.nil? then
        if @upload_image then
          time_now  = Time.now.strftime('%Y%m%d.%H%M%S')
          extension = @upload_image.original_filename.split('.').last.downcase
          filename  = "contact.#{self.id}.#{time_now}.#{extension}"
          path      = File.join(DIRECTORY, filename)

          cleanup_image

          File.open(path, "wb") do |f|
            f.write(@upload_image.read)
          end
          
          self[:image] = filename
        else
          cleanup_image
          self[:image] = nil
        end
        @upload_image = nil
        save
      end
    end

    def cleanup_image
      if self.image then
        path = File.join(DIRECTORY, self.image)
        File.unlink(path) rescue nil
      end
    end
    
    def save_phones
      self.addressbook_phones.each do |addressbook_phone|
        addressbook_phone.save(false)
      end

    end
    
    def save_groups
      self.addressbook_group_phones.each do |addressbook_group_phone|
        addressbook_group_phone.save(false)
      end
    end
end
