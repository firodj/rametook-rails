require 'rails_generator/generators/components/scaffold/scaffold_generator'

class ToombilaSchemaDumper < ActiveRecord::SchemaDumper
  def self.dump_table(table, stream=STDOUT, connection=ActiveRecord::Base.connection)
    new(connection).dump_table(table, stream)
    stream
  end

  def dump_table(table, stream)
    table(table, stream)
  end
end

class ToombilaScaffoldingSandbox
  include ActionView::Helpers::ActiveRecordHelper

  attr_accessor :form_action, :singular_name, :suffix, :model_instance

  def sandbox_binding
    binding
  end

  # override from ActiveRecordHelper
  #def all_input_tags(record, record_name, options)
  #   input_block = options[:input_block] || default_input_block
  #   record.class.content_columns.collect{ |column| input_block.call(record_name, column) }.join("\n")
  #end

  # override from ActiveRecordHelper
  def default_input_block
    # Proc.new { |record, column| %(<p><label for="#{record}_#{column.name}">#{column.human_name}</label><br />#{input(record, column.name)}</p>) }
    Proc.new { |record, column| input_block = <<-END_ROW 
<p>
	<label><%=h print_words('#{column.human_name.downcase}').capitalize_words %></label>
	#{input(record, column.name, :limit => column.limit)}
</p>
END_ROW
      column.name == 'image' ? "<!--\n<% if false then %>\n" + input_block.gsub(/^/im, '#') + "<% end %>\n-->" : input_block
    }
  end
end

#module ToombilaScaffoldInstanceTag
class ActionView::Helpers::InstanceTag
  # @object_name, @method_name
  def to_input_field_tag(field_type, options={})    options[:size] = options.delete(:limit)
    #tag_params << "'size' => '#{limit}'" if limit and limit < 255
    options[:class] ||= 'input-text'
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    
    "<%= f.#{field_type}_field #{tag_params.join(', ')} %>"
  end

  def to_text_area_tag(options = {})

    limit = options.delete(:limit)
    options[:class] ||= 'input-text-area'
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    "<%= f.text_area #{tag_params.join(', ')} %>"
  end

  def to_date_select_tag(options = {})
    limit = options.delete(:limit)
    options[:size] = 10
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    "<%= f.text_field #{tag_params.join(', ')} %>" + 
      "<%= calendar_for('#{@object_name}_#{@method_name}') %>"
  end

  def to_datetime_select_tag(options = {})\
    limit = options.delete(:limit)
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    "<%= f.datetime_select #{tag_params.join(', ')} %>"
  end
  
  def to_time_select_tag(options = {})
    limit = options.delete(:limit)
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    "<%= f.time_select #{tag_params.join(', ')} %>"
  end

  def to_boolean_select_tag(options = {})
    limit = options.delete(:limit)
    options[:class] ||= 'input-checkbox'
    tag_params = [@method_name.inspect]
    tag_params << options.inspect unless options.blank?
    "<%= f.check_box #{tag_params.join(', ')} %>"    
  end
end
#ActionView::Helpers::InstanceTag.send(:include, ToombilaScaffoldInstanceTag)

class ToombilaScaffoldGenerator < ScaffoldGenerator
  def manifest    
    record do |m|
      # Check for class naming collisions.
      m.class_collisions controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}ControllerTest", "#{controller_class_name}Helper"
      m.class_collisions class_path, class_name #, "#{class_name}Test"

      # Controller, helper, views, and test directories.
      m.directory File.join('app/controllers', controller_class_path)
      # m.directory File.join('app/helpers', controller_class_path)
      m.directory File.join('app/views', controller_class_path, controller_file_name)
      # m.directory File.join('app/views/layouts', controller_class_path)
      m.directory File.join('test/functional', controller_class_path)

      # Depend on model generator but skip if the model exists.
      #m.dependency 'model', [singular_name], :collision => :skip, :skip_migration => true
      # Or use this
      m.directory File.join('app/models', class_path)
      m.template 'model.rb', 
        File.join('app/models', class_path, "#{file_name}.rb")

      m.reload_model

      # Scaffolded forms.
      m.complex_template "view_form.rhtml",
        File.join('app/views',
                  controller_class_path,
                  controller_file_name,
                  "_form.rhtml"),
        :insert => 'insert_form_scaffolding.rhtml',
        :sandbox => lambda { create_sandbox },
        :begin_mark => 'form',
        :end_mark => 'eoform',
        :mark_id => singular_name

      # Scaffolded views. partial or page
      scaffold_views.each do |action_view|
        view_partial = action_view.scan(/^_(.*)/).flatten
        action = view_partial.empty? ? action_view : view_partial
        m.template "view_#{action}.rhtml",
                   File.join('app/views',
                             controller_class_path,
                             controller_file_name,
                             "#{action_view}.rhtml"),
                   :assigns => { :action => action }
      end
        
      # Controller class, functional test, helper, and views.
      m.template 'controller.rb',
                  File.join('app/controllers',
                            controller_class_path,
                            "#{controller_file_name}_controller.rb")

      m.template 'functional_test.rb',
                  File.join('test/functional',
                            controller_class_path,
                            "#{controller_file_name}_controller_test.rb")

      m.template 'helper.rb',
                  File.join('app/helpers',
                            controller_class_path,
                            "#{controller_file_name}_helper.rb")
                            
      # Scaffolded RJS
      scaffold_rjs.each do |action_ajax|
        action = action_ajax
        m.template "ajax_#{action}.rjs",
                   File.join('app/views',
                             controller_class_path,
                             controller_file_name,
                             "#{action_ajax}.rjs"),
                   :assigns => { :action => action }
      end
      
      # Layout and stylesheet.
      # Use global application.rhtml and main.css
      # m.template 'layout.rhtml',
      #            File.join('app/views/layouts',
      #                      controller_class_path,
      #                      "#{controller_file_name}.rhtml")
      #
      # m.template 'style.css',     'public/stylesheets/scaffold.css'

      # Unscaffolded views.
      unscaffolded_actions.each do |action|
        path = File.join('app/views',
                          controller_class_path,
                          controller_file_name,
                          "#{action}.rhtml")
        m.template "controller:view.rhtml", path,
                   :assigns => { :action => action, :path => path}      
      end

      # Migration
      m.migration_template(
        'migration.rb', 'db/migrate',
        :assigns => { 
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}",
          :attributes     => attributes
        }, 
        :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      )
      
      # Routing
      m.route_resources controller_file_name
    end
  end

  def scaffold_views
    %w{list _item _show _filter _new _new_error _edit _edit_error}
  end
  
  def scaffold_rjs
    %w{item_update}
  end
   
  def create_sandbox
    sandbox = ToombilaScaffoldingSandbox.new
    sandbox.singular_name = singular_name
    begin
      sandbox.model_instance = model_instance
      sandbox.instance_variable_set("@#{singular_name}", sandbox.model_instance)
    rescue ActiveRecord::StatementInvalid => e
        logger.error "Before updating scaffolding from new DB schema, try creating a table for your model (#{class_name})"
        raise SystemExit
    end
    sandbox.suffix = suffix
    sandbox
  end
end
module ToombilaScaffoldCreate
  def reload_model
    logger.reload class_name
    class_name.constantize
  end

end

module ToombilaScaffoldDestroy
  def reload_model
    # nothing to do
  end
  
  #alias_method :complex_template, :file
  #def complex_template(relative_source, relative_destination, template_options = {})
    # nothing should be done here
  #end
end

Rails::Generator::Commands::Create.send :include, ToombilaScaffoldCreate
Rails::Generator::Commands::Destroy.send :include, ToombilaScaffoldDestroy

