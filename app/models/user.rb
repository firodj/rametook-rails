require 'digest/sha1'
class User < ActiveRecord::Base
  belongs_to :department
  before_create :make_activation_code
  before_destroy :before_destroy
  
  after_create :create_business_contact
  after_save :update_business_contact
  
  # Virtual attribute for the unencrypted password
  has_and_belongs_to_many :roles
  
  attr_accessor :password

  validates_presence_of     :login, :email, :department_id
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_format_of       :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :on => :create
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_presence_of     :first_name
  before_save               :encrypt_password

  has_many :addressbook_groups # not uzed
  has_many :addressbook_contacts
  belongs_to :business_contact, 
    :class_name => 'AddressbookContact',
    :foreign_key => 'business_contact_id'
  
  has_many :addressbook_group_users
  has_many :operated_groups, :through => :addressbook_group_users, :uniq => true
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    # u = find_by_login(login) # need to get the salt (original act code)
    # Below is with activation code:
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    u && u.authenticated?(password) ? u : nil
  end

  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # default item name to display
  def display_name
    [read_attribute(:first_name), read_attribute(:last_name)].join(' ')
  end

  def self.find_all
    find(:all, :order => 'first_name ASC, last_name ASC')
  end
  
  def self.find_by_id(id)
    find(:first, :conditions => {:id => id})
  end
  
  # array containing texts and values  
  def self.find_all_for_select_option(blank = nil)
    select_option(find_all, blank)
  end
  
  def self.select_option(objects, blank = nil)
    options = objects.map { |e| [e.display_name, e.id] }
    options.unshift([blank,'']) unless blank.nil?
    options
  end
  
  def can_destroyed?
    # list of associations to check (automatic)
    has_assocs = []
    self.class.reflections.each do |r_name, r|
      next if r_name == :roles
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
  
  def create_business_contact
    return if self.business_contact # already have, dont create other
    self.business_contact = AddressbookContact.create!(
      :name          => self.display_name,
      :department_id => self.department_id,
      :user_id       => self.id,
      :public        => false
    )
  end
  
  def update_business_contact
    create_business_contact unless self.business_contact
    return unless self.business_contact
    self.business_contact.update_attributes(
      :name => self.display_name,
      :email => self.email,
      :department_id => self.department_id,
      :address => self.address,
      :city => self.city,
      :country => self.country,
      :birthday => self.birthday
    )
  end
  
  def attributes_from_business_contact(business_contact)
    if business_contact.class <= AddressbookContact then
      self.business_contact = business_contact
    elsif business_contact.nil?
      return
    else
      self.business_contact = AddressbookContact.find_by_id(business_contact.to_i)    
    end
    return unless self.business_contact
    
    self.first_name, self.last_name = self.business_contact.display_name.split(' ', 2)
    self.email = self.business_contact.email
    self.address = self.business_contact.address
    self.city = self.business_contact.city
    self.country = self.business_contact.country
    self.birthday = self.business_contact.birthday
    true
  end
  
  def selecting_groups_attributes=(groups_attributes)
    groups_to_add = []
    groups_to_del = self.operated_groups.map(&:id)
    
    groups_attributes.each_pair { |group_id_s, attribs|
      if attribs['selected'].to_i > 0 then
        unless group_id = groups_to_del.delete(group_id_s.to_i) then
          groups_to_add << group_id_s.to_i
        end
      end
    }
    
    AddressbookGroup.find(groups_to_del).each { |group|
      self.operated_groups.delete(group)
    }
    
    groups_to_add.each { |group_id|
      self.addressbook_group_users.build(
        :addressbook_group_id => group_id, 
        :operator => true
      )
    }
  end
  
  protected
    # If you're going to use activation, uncomment this too
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
    
     def before_destroy
      can_destroyed?
    end
end
