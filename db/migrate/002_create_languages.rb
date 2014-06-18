class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
       t.column :plugins, :string
       t.column :name, :string
       t.column :value, :string
       t.column :language, :string
    end

    say_with_time "Creating general pharses for english language..." do
      Language.create :plugins => 'general', :name => "welcome", :value => "welcome", :language => "en"
      Language.create :plugins => 'general', :name => "login successful", :value => "login successful!", :language => "en"
      Language.create :plugins => 'general', :name => "not enough access level", :value => "not enough access level", :language => "en"
      Language.create :plugins => 'general', :name => "you are currently using", :value => "you are currently using", :language => "en"
      Language.create :plugins => 'general', :name => "you are login as", :value => "you are login as", :language => "en"
      Language.create :plugins => 'general', :name => "image", :value => "image", :language => "en"
      Language.create :plugins => 'general', :name => "image2", :value => "make sure your image size will be best viewed at 60 x 60 pixel", :language => "en"
      Language.create :plugins => 'general', :name => "sign up", :value => "sign up", :language => "en"
      Language.create :plugins => 'general', :name => "activate", :value => "activate", :language => "en"
      Language.create :plugins => 'general', :name => "activation code", :value => "activation code", :language => "en"
      Language.create :plugins => 'general', :name => "login", :value => "login", :language => "en"
      Language.create :plugins => 'general', :name => "logout", :value => "logout", :language => "en"
      Language.create :plugins => 'general', :name => "address", :value => "address", :language => "en"
      Language.create :plugins => 'general', :name => "city", :value => "city", :language => "en"
      Language.create :plugins => 'general', :name => "birthday", :value => "birthday", :language => "en"
      Language.create :plugins => 'general', :name => "displayname", :value => "display name", :language => "en"
      Language.create :plugins => 'general', :name => "username", :value => "username", :language => "en"
      Language.create :plugins => 'general', :name => "department", :value => "department", :language => "en"
      Language.create :plugins => 'general', :name => "access level", :value => "access level", :language => "en"
      Language.create :plugins => 'general', :name => "email", :value => "email", :language => "en"
      Language.create :plugins => 'general', :name => "password", :value => "password", :language => "en"
      Language.create :plugins => 'general', :name => "phone", :value => "phone", :language => "en"
      Language.create :plugins => 'general', :name => "card_id", :value => "card ID", :language => "en"
      Language.create :plugins => 'general', :name => "confirm", :value => "confirm", :language => "en"
      Language.create :plugins => 'general', :name => "are you sure", :value => "are you sure?", :language => "en"
      Language.create :plugins => 'general', :name => "remember me", :value => "remember me?", :language => "en"
      Language.create :plugins => 'general', :name => "save", :value => "save", :language => "en"
      Language.create :plugins => 'general', :name => "add", :value => "add", :language => "en"
      Language.create :plugins => 'general', :name => "edit", :value => "edit", :language => "en"
      Language.create :plugins => 'general', :name => "back", :value => "back", :language => "en"
      Language.create :plugins => 'general', :name => "has been created", :value => "has been created", :language => "en"
      Language.create :plugins => 'general', :name => "has been updated", :value => "has been updated", :language => "en"
      Language.create :plugins => 'general', :name => "has been deleted", :value => "has been deleted", :language => "en"
      Language.create :plugins => 'general', :name => "optional", :value => "optional", :language => "en"
      Language.create :plugins => 'general', :name => "powered", :value => "powered", :language => "en"
      Language.create :plugins => 'general', :name => "by", :value => "by", :language => "en"
      Language.create :plugins => 'general', :name => "rails", :value => "Ruby on Rails", :language => "en"
      Language.create :plugins => 'general', :name => "leave blank not update", :value => "leave blank if you do not want to update", :language => "en"
      Language.create :plugins => 'general', :name => "home", :value => "home", :language => "en"
      Language.create :plugins => 'general', :name => "dashboard", :value => "dashboard", :language => "en"
      Language.create :plugins => 'general', :name => "my account", :value => "my account", :language => "en"
      Language.create :plugins => 'general', :name => "configuration", :value => "configuration", :language => "en"
      Language.create :plugins => 'general', :name => "manage", :value => "manage", :language => "en"
      Language.create :plugins => 'general', :name => "manage user", :value => "manage user", :language => "en"
      Language.create :plugins => 'general', :name => "successful", :value => "creation process successful", :language => "en"
      Language.create :plugins => 'general', :name => " ", :value => " ", :language => "en"
      Language.create :plugins => 'general', :name => "registration success", :value => "registration success, please check your email then activate your account", :language => "en"
    end
  end

  def self.down
    drop_table :languages
  end
end
