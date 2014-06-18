class <%= class_name %> < ActiveRecord::Base
  
  IMAGE_DIRECTORY = 'public/images/'
  
<%
  connection = ActiveRecord::Base.connection
  if connection.respond_to?(:pk_and_sequence_for)
    pk, pk_seq = connection.pk_and_sequence_for(table_name)
  end
  pk ||= 'id'
  
  display_name_fields = [pk,'name','title','display_name']
  display_name_index = 0 
  last_idx = display_name_fields.size-1
  
  connection.columns(table_name).each do |c|
    if display_name_index < last_idx
      idx = display_name_fields.index c.name
      unless idx.nil?
        display_name_index = idx if idx > display_name_index
      end
    end

    if c.name == pk then -%>
  # primary_key :<%= c.name %>
<%- else 
      belong = c.name.scan(/(.*)_id$/).flatten 
      if c.type == :boolean then -%>
  validates_inclusion_of :<%= c.name %>, :in => [true, false]
<%-   elsif c.name != 'image' then -%>
  validates_presence_of :<%= c.name %>
<%-   end 
      if c.type != :boolean then -%>
  # validates_uniqueness_of :<%= c.name %>
<%-   end
      if !belong.empty? then -%>
  belongs_to :<%= belong[0] %>
<%-   end 
    end
  end -%>

  # perevent from being destroyed
  # just disable it if it's annoying  
  before_destroy :prevent_if_cannot_destroyed

  # please disable these lines if there is no image field
  after_save :process_image
  after_destroy :cleanup_image
  
  # display_name 
  # default item name to display
  def display_name
    self[:<%= display_name_fields[display_name_index] %>]
  end

  def self.find_by_id(id)
    if id.class <= Array then
      find(:all, :conditions => ['id IN (?)', id])
    else
      find(:first, :conditions => {:id => id})
    end
  end
    
  def self.find_all
    find(:all, :order => '`<%= display_name_fields[display_name_index] %>` ASC')
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
  # image must be false to remove it!, (not from here!)
  # image must be nil if there's nothing to do with image
  def image=(image)
    @upload_image = image.respond_to?(:original_filename) ? image : @upload_image
  end
  
  def remove_image=(value)
    @upload_image = false if value.to_i > 0
  end
  
  def remove_image
    @upload_image == false
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
        if @upload_image then
          time_now  = Time.now.strftime('%Y%m%d.%H%M%S')
          extension = @upload_image.original_filename.split('.').last.downcase
          filename  = "<%= singular_name %>.#{self.id}.#{time_now}.#{extension}"
          path      = File.join(IMAGE_DIRECTORY, filename)

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
        save!
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
