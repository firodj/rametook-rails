class DesignerDatabaseController < ApplicationController
  def index
    @designer_tables = Toombila::DesignerTable.find_all_tables
  end
  
  def new_table
    if params[:value] && !params[:value].strip.empty? then
      name = Toombila::DesignerTable.correct_name(params[:value].strip)
      result = Toombila::DesignerTable.create_table(name)
      flash[:notice] = result == true ? "Success creating table '#{name}'!" : result
    end
    redirect_to :action => 'index'
  end
  
  def edit_table
    if params[:value] && !params[:value].strip.empty? then
      name = params[:old_value]
      new_name = Toombila::DesignerTable.correct_name(params[:value].strip)
      if name != new_name then
        result = Toombila::DesignerTable.rename_table(name, new_name)
        flash[:notice] = result == true ? "Success renaming table from '#{name}' to '#{new_name}'!" : result
      end
    end
    redirect_to :action => 'index'
  end
  
  def delete_table
    if params[:value] && !params[:value].strip.empty? then
      name = Toombila::DesignerTable.correct_name(params[:value].strip)
      result = Toombila::DesignerTable.drop_table(name)
      flash[:notice] = result == true ? "Success deleting table '#{name}'!" : result
    end
    redirect_to :action => 'index'
  end
  
  def list
    @table = Toombila::DesignerTable.new(params[:table])
    redirect_to :action => 'index' if @table.nil?
  end
  
  def edit_table_then_list
    if params[:value] && !params[:value].strip.empty? then
      name = params[:old_value]
      new_name = Toombila::DesignerTable.correct_name(params[:value].strip)
      if name != new_name then
        result = Toombila::DesignerTable.rename_table(name, new_name)
        flash[:notice] = result == true ? "Success renaming table from '#{name}' to '#{new_name}'!" : result
      end
    end
    redirect_to :action => 'list', :table => result == true ? new_name : name
  end
  
  def new_column
    if params[:table] && params[:value] && !params[:value].strip.empty? then
      table = Toombila::DesignerTable.new(params[:table])
      name = Toombila::DesignerTable.correct_name(params[:value].strip)
      result = table.add_column(name)
      flash[:notice] = result == true ? "Success creating column '#{name}'!" : result
    end
    redirect_to :action => 'list', :table => params[:table]
  end
  
  def rename_column
    if params[:table] && params[:value] && !params[:value].strip.empty? then
      name = params[:old_value]
      new_name = Toombila::DesignerTable.correct_name(params[:value].strip)
      if name != new_name then
        table = Toombila::DesignerTable.new(params[:table])
        result = table.rename_column(name, new_name)
        flash[:notice] = result == true ? "Success renaming column from '#{name}' to '#{new_name}'!" : result
      end
    end
    redirect_to :action => 'list', :table => params[:table]
  end
  
  def delete_column
    if params[:table] && params[:value] && !params[:value].strip.empty? then
      table = Toombila::DesignerTable.new(params[:table])
      name = Toombila::DesignerTable.correct_name(params[:value].strip)
      result = table.remove_column(name)
      flash[:notice] = result == true ? "Success deleting column '#{name}'!" : result
    end
    redirect_to :action => 'list', :table => params[:table]
  end
  
  def move_column
    table = Toombila::DesignerTable.new(params[:table])
    result = table.move_column(params[:from_name], params[:to_name])
    render :update do |page|
      if result == true then
        page.redirect_to :action => 'list', :table => params[:table]
      else
        unless result.nil?
        page['message'].show
        page.replace_html "message", result.gsub('<', '&lt;')
        end
      end
    end
  end
  
  def edit_column
    @table = Toombila::DesignerTable.new(params[:table])
    @column = @table.columns.detect { |column| column.name == params[:value] }
    render :update do |page|
      page['message'].hide
      page.replace_html 'message', ''
      page.replace_html "column_type_#{@column.name}", :partial => 'column'
    end
  end
  
  def cancel_column
    @table = Toombila::DesignerTable.new(params[:table])
    @column = @table.columns.detect { |column| column.name == params[:value] }
    render :update do |page|
      page.replace_html "column_type_#{@column.name}", :partial => 'type'
    end
  end
  
  def update_column
    @table = Toombila::DesignerTable.new(params[:table])
    options = {:default => nil}
    options[:limit] = params[:limit].to_i if !params[:limit].nil? && !params[:limit].empty?
    options[:precision] = params[:precision].to_i if !params[:precision].nil? && !params[:precision].empty?
    options[:scale] = params[:scale].to_i if !params[:scale].nil? && !params[:scale].empty?
    
    result = @table.change_column(params[:value], params[:type].to_sym, options)
    @column = @table.columns.detect { |column| column.name == params[:value] }
    
    render :update do |page|
      page.replace_html "message", result == true ? '' : result.gsub('<', '&lt;')
      result == true ? page['message'].hide : page['message'].show
      page.replace_html "column_type_#{@column.name}", :partial => 'type'
    end
  end
  
  def remove_primary
    @table = Toombila::DesignerTable.new(params[:table])
    @column = @table.columns.detect { |column| column.name == params[:value] }
    result = @table.change_column(@column.name, @column.type, {:default => nil})
    result = @table.drop_primary_key if result
    @column = @table.columns.detect { |column| column.name == params[:value] }
    
    render :update do |page|
      page.replace_html "message", result == true ? '' : result.gsub('<', '&lt;')
      result == true ? page['message'].hide : page['message'].show
      page.replace_html "column_type_#{@column.name}", :partial => 'type'
    end
  end
end

