class Department < ActiveRecord::Base
  # primary_key :id
  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :parent_id
  has_many                :users  
  before_destroy          :before_destroy
  
  acts_as_tree
  
  # default item name to display
  def display_name
    read_attribute :name
  end

  def self.find_all
    find(:all, :order => 'name ASC')
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
  
  # collect all descendants
  def descendants(with_level = false)
    nodes = self.children.map { |child| with_level ? [child, 0] : child }
    i = 0
    while node = nodes[i] do
      (with_level ? node[0] : node).children.reverse.each do |child|
        nodes.insert i+1, (with_level ? [child, node[1]+1] : child)
      end
      i += 1
    end
    nodes
  end
  
  # return department that can be parent for this
  def find_available_parents
    deleted_ids = {self.id => true}
    descendants.each {|e| deleted_ids[e.id] = true}
    self.class.find_all.delete_if { |e| deleted_ids[e.id] }
  end
  
  def find_available_parents_for_select_option(blank = nil)
  	self.class.select_option(find_available_parents, blank)
  end
  
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
  
  private
    def before_destroy
      can_destroyed?
    end
end
