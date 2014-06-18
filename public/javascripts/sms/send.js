function show_remaining(overhead) 
{
	$('sms_send_length').update( 160 - overhead - $('sms_send_message').value.length );
}

function update_addressbook_results(addressbook) 
{
  // <%= url_for(:action => 'update_addressbook_result').to_json %>
  url = '/sms_send/update_addressbook_result';
  $('contact_spinner').show();
  new Ajax.Request(url,
    {
      // {addressbook: $('filter_addressbook').value,
      //  department_id: $('filter_department_id').value}
      parameters: $H({addressbook: addressbook}),
      onLoaded: function(transport) { $('contact_spinner').hide() },
      onSuccess: function(transport) {
        $('recipient_results').update('');
        
        transport.responseJSON.each(function(contact) {
          html  = '<li style="cursor: pointer;" onclick="add_contacts(this,' + contact.id + ',\'' + contact.type + '\'); return false;">';
          html += contact.title
          html += ' ' + '(' + contact.info + ')'
          /*
          if (contact.type == 'group')   
            html += ' ' + '(' + contact.info + ' contacts)';
          else if (contact.type == 'contact')
            html += ' ' + '(' + contact.info + ' phones)';
          */
          html += '</li>';
          
          //if (typeof console != 'undefined') console.log(html); // debug

          $('recipient_results').insert(html);
        });
      }
    }
  )
}

function add_contacts(title_href, contact_id, contact_type) {
  // <%= url_for(:action => 'update_addressbook_group').to_json %> ,
  // <%= url_for(:action => 'update_addressbook_contact').to_json %> };
  url_for = { group: '/sms_send/update_addressbook_group',
    contact: '/sms_send/update_addressbook_contact' };
    
  $('phone_spinner').show();
  
  new Ajax.Request( url_for[contact_type],
    {
      parameters: $H({contact_id: contact_id}),
      onLoaded: function(transport) { $('phone_spinner').hide() },
      onSuccess: function(transport) {
        //scroll_to_id = '';
        transport.responseJSON.each(function(phone) {
          title_member = '<strong>' + phone.contact + '</strong> ' + phone.info + ' <em>' + phone.type + '</em>';
          
          elem_id = 'phone_' + phone.id // + '_' + phone.type;
          if ($(elem_id)) {
            // $(elem_id).highlight();
          } else {
            html  = '<li style="cursor: pointer;" onclick="del_contact(this); return false;" id="' + elem_id + '">' + title_member;
            html += '<input type="hidden" name="recipients[]" value="' + phone.value + '">';
            html += '</li>';
                        
            // if (typeof console != 'undefined') console.log(html); // debug 
            $('recipient_selects').insert(html);
            //scroll_to_id = elem_id
          }
        });
        
        //if (!empty(scroll_to_id)) $(scroll_to_id).scrollTo();
      }
    }
  )
}

function add_direct() {
  contact_id = $('direct_number').value
  if (contact_id == '')
    return;
    
  field_id = 'direct'
  title_member = contact_id
  elem_id = 'contact_' + contact_id + '_' + field_id;
  
  html  = '<li style="cursor: pointer;" onclick="del_contact(this); return false;" id="' + elem_id + '">' + title_member;
  html += '<input type="hidden" name="recipients[]" value="' + contact_id + ',' + field_id + '">';
  html += '</li>';
  
  if (typeof console != 'undefined')
        console.log(html);
        
  $('recipient_selects').insert(html);
      
  $('direct_number').value = ''
}

function del_contact(title_href) {
  Effect.Fade( title_href, { duration: 0.7,
    afterFinish: function(effect) {
      // title_href.next('br').remove()
      title_href.remove()
    }
  });
}

function sort_contacts() {
  childs = $('recipient_selects').childElements().sortBy(function(s) { return s.innerHTML; } );
  $('recipient_selects').update();
  //console.log(childs);
  childs.each(function(e) {
    $('recipient_selects').insert(e);
  } )
}

function validates_numericality_of(field) {
  field.value.search(/[^0-9]+/) >= 0 ? false : true
}

function corrects_numericality_of(field) {
  val = field.value.gsub(/[^0-9]+/,'');
  if (val != field.value)
    field.value = val;
}
