class SmsReply < ActiveRecord::Base
  include Rametook::SmsReplyTemplator
  
  IMAGE_DIRECTORY = 'public/images/'
  
  # primary_key :id
  validates_presence_of :function
  validates_presence_of :message
  validates_inclusion_of :active, :in => [true, false]

  # perevent from being destroyed
  # just disable it if it's annoying  
  before_destroy :prevent_if_cannot_destroyed

  # please disable these lines if there is no image field
  after_save :process_image
  after_destroy :cleanup_image
  
  # display_name 
  # default item name to display
  def display_name
    self[:id]
  end

  def self.find_by_id(id)
    if id.class <= Array then
      find(:all, :conditions => ['id IN (?)', id])
    else
      find(:first, :conditions => {:id => id})
    end
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

  # +image+ is default attribute/column to save image file name
  # image must be a stream/file object (have original_filename method) to save it!,
  # image must be false to remove it!,
  # image must be nil if there's nothing to do with image
  def image=(image)
    @upload_image = image.respond_to?(:original_filename) ? image : nil
  end
  
  def action=(action)
    self[:action] = action.blank? ? nil : action
  end
  
  def tags=(tags)
    self[:tags] = tags.blank? ? nil : tags
  end
  # request to delete the image
  def remove_image=(remove_image)
    @remove_uploaded_image = remove_image
  end
  
  private
    # return true/nil, then continue to destroy
    # return false, then cancel to destroy
    def prevent_if_cannot_destroyed
      can_destroyed?
    end
    
    # processing images to be saved or deleted
    # priority to delete the file
    def process_image
      unless @upload_image.nil? then
        if @remove_uploaded_image then
          cleanup_image
          self[:image] = nil
        elsif @upload_image then
          time_now  = Time.now.strftime('%Y%m%d.%H%M%S')
          extension = @upload_image.original_filename.split('.').last.downcase
          filename  = "sms_reply.#{self.id}.#{time_now}.#{extension}"
          path      = File.join(IMAGE_DIRECTORY, filename)

          cleanup_image

          File.open(path, "wb") do |f|
            f.write(@upload_image.read)
          end
          
          self[:image] = filename
        end
        @remove_uploaded_image = nil
        @upload_image = nil
        save
      end
    end

    # cleanup image, when deleting
    def cleanup_image
      if self[:image] then
        path = File.join(IMAGE_DIRECTORY, self.image)
        File.unlink(path) rescue nil
      end
    end
end
