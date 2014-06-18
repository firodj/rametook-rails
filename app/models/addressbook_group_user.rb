class AddressbookGroupUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :addressbook_group
  belongs_to :operated_group, :class_name => 'AddressbookGroup'
    
  :operator_for_groups
end
