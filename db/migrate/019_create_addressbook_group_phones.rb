class CreateAddressbookGroupPhones < ActiveRecord::Migration
  def self.up
    create_table :addressbook_group_phones do |t|
    end
  end

  def self.down
    drop_table :addressbook_group_phones
  end
end
