class CreateAddressbookGroupUsers < ActiveRecord::Migration
  def self.up
    create_table :addressbook_group_users do |t|
    end
  end

  def self.down
    drop_table :addressbook_group_users
  end
end
