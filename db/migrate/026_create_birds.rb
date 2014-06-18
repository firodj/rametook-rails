class CreateBirds < ActiveRecord::Migration
  def self.up
      create_table "birds", :force => true do |t|
    t.column "name",        :string
    t.column "description", :text
    t.column "die_at",      :date
    t.column "created_at",  :datetime
    t.column "user_id",     :integer
    t.column "fine",        :boolean
    t.column "sleep_at",    :time
  end

#    create_table :birds do |t|
#    end
  end

  def self.down
    drop_table :birds #rescue nil 
  end
end
