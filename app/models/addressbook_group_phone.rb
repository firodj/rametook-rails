class AddressbookGroupPhone < ActiveRecord::Base
  # validates_presence_of :field
  # validates_presence_of :addressbook_contact_id
  # validates_presence_of :addressbook_group_id
  
  belongs_to :addressbook_contact
  
  belongs_to :addressbook_phone
  belongs_to :addressbook_group
  
  
end
