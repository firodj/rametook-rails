module ApplicationHelper
  # link_back_to_list
  def link_back_to_list
    content_tag(:div, link_to( print_words('back').capitalize , :action => "list"), :class => "buttons")
  end
  
  # link_to_edit
  def link_to_edit(obj,type)
    link_to image_tag("/images/icon-detail.gif"), :action => 'edit'+type, :id => obj
  end
  
  # link_to_show
  def link_to_show(obj,type)
    link_to image_tag("/images/icon-show.png"), :action => 'show'+type, :id => obj
  end
  
  # link_to_destroy
  def link_to_destroy(obj,type)
    link_to_remote image_tag("/images/icon-delete.gif"), :url => { :action => 'destroy'+type, :id => obj }, :confirm => print_words('are you sure').capitalize , :method => :delete
  end
  
  # static_progress_bar
  def static_progress_bar(obj)
    %(<p style="width:200px;border:1px solid #888; padding:1px;margin-right:5px;float:left;"><span style="width:#{obj}%; background:#060;display:block;text-align:center;color:#fff;">#{obj}%</span></p>)
  end

  # link_to_add_new
  def link_to_add_new(obj = print_words('add').capitalize )
    %(<div class="buttons">#{link_to(obj, :action => 'new')}</div>)
  end

  # link_to_paginator
  def link_to_paginator(paginator, options={}, html_options={})   
    options[:link_to_current_page] = true
    name = options[:name] || :page
    params = options[:params].clone || {}
    current_page = paginator.current.number

    html = 'Page: '
    if paginator.current.previous
      params[name] = paginator.current.previous
      html << link_to( '&#171;', params, html_options)
      html << %( )
    end
    
    html << pagination_links_each(paginator, options) do |n|
      if n == current_page then
        %(<span class="currentPage">#{n}</span>)
      else
        params[name] = n
        link_to(n.to_s, params, html_options)
      end

    end

    if paginator.current.next
      params[name] = paginator.current.next
      html << %( )
      html << link_to( '&#187;', params, html_options)
    end
    "<div style=\"width:100%;text-align:right;\">"+html+"</div>"
  end   

  # Dateselect Mini Calendar
  def calendar_for(field_id)
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
    javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end

  def radio_select(object_name, method, choices, options = {}, html_options = {})
    html = ''
    choices.each { |choice|
      html << radio_button(object_name, method, choice[1])
      html << " <span class=\"label_radio_select\">" + choice[0].to_s + "</span>"
      html << '<br />'
    }
    html
	end
	
end
