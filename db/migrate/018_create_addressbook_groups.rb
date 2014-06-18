class CreateAddressbookGroups < ActiveRecord::Migration
  def self.up
      create_table "addressbook_groups", :force => true do |t|
    t.column "name",    :string
    t.column "user_id", :integer, :limit => 255
  end

#    create_table :addressbook_groups do |t|
#    end
  end

  def self.down
    drop_table :addressbook_groups #rescue nil 
  end
end
