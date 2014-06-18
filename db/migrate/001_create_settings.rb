class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings, :force => true do |t|
       t.column :plugins,     :string
       t.column :name,        :string
       t.column :value,       :string
       t.column :description, :string
    end

    say_with_time "Creating general settings..." do
      Setting.create :plugins => 'general', :name => 'site name', :value => 'Toombila.org'
      Setting.create :plugins => 'general', :name => 'subtitle',  :value => 'Simple Ruby on Rails Groupware'
      Setting.create :plugins => 'general', :name => 'site email', :value => 'info@toombila.org'
      Setting.create :plugins => 'general', :name => 'site host', :value => 'http://localhost:3000'
      Setting.create :plugins => 'general', :name => 'engine',    :value => 'Toombila 0.4 beta (Banga)'
      Setting.create :plugins => 'general', :name => 'language',  :value => 'en', :description => 'Use ISO code (en, id, au etc.)'
      Setting.create :plugins => 'general', :name => 'open signup', :value => 'yes', :description => 'User available to register membership (yes/no)'
    end
  end

  def self.down
    drop_table :settings
  end
end
