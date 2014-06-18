module DesignerDatabaseHelper
  def inplace_editor(text, value, url, id, hiddens = {})
    html = ''
    html << %Q{<span id="inpe_target_#{id}">}
    html << link_to_function(text) do |page|
      page["inpe_target_#{id}"].hide
      page << "$(\"inpe_form_#{id}\").style['display'] = 'inline'"
      page << "$(\"inpe_form_#{id}\").value.value = #{value.to_json}"
      page << "$(\"inpe_form_#{id}\").value.focus()"
    end
    html << %Q{</span>}
    html << form_tag(url_for(url), {:method => 'post', :id => "inpe_form_#{id}", :style => 'display: none; padding: 0px; margin: 0px;'})
    html << text_field_tag('value')
    html << hidden_field_tag('old_value', value)
    hiddens.each_pair { |k,v|
    html << hidden_field_tag(k,v)
    }
    html << submit_tag('Ok')
    html << link_to_function('Cancel') do |page|
      page["inpe_target_#{id}"].show
      page["inpe_form_#{id}"].hide
    end
    html << %Q{</form>}
    html
  end
end
