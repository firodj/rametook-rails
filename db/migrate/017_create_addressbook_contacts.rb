class CreateAddressbookContacts < ActiveRecord::Migration
  def self.up
      create_table "addressbook_contacts", :force => true do |t|
    t.column "name",          :string
    t.column "email",         :string
    t.column "phone",         :string
    t.column "mobile1",       :string
    t.column "mobile2",       :string
    t.column "description",   :text
    t.column "address",       :string
    t.column "city",          :string
    t.column "country",       :string
    t.column "birthday",      :date
    t.column "department_id", :integer, :limit => 255
    t.column "userimage",     :string
    t.column "user_id",       :integer, :limit => 255
    t.column "forpublic",     :boolean,                :default => false
  end

#    create_table :addressbook_contacts do |t|
#    end
  end

  def self.down
    drop_table :addressbook_contacts #rescue nil 
  end
end
