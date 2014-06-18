class CreateSmsInboxFilters < ActiveRecord::Migration
  def self.up
      create_table "sms_inbox_filters", :force => true do |t|
    t.column "addressbook_contact_id", :integer
    t.column "department_id",          :integer
    t.column "group_id",               :integer
    t.column "user_id",                :integer
  end

#    create_table :sms_inbox_filters do |t|
#    end
  end

  def self.down
    drop_table :sms_inbox_filters #rescue nil 
  end
end
