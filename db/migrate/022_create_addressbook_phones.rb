class CreateAddressbookPhones < ActiveRecord::Migration
  def self.up
    create_table :addressbook_phones do |t|
    end
  end

  def self.down
    drop_table :addressbook_phones
  end
end
