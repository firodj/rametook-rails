module Toombila
   
    module ActionControllerRescue 
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods #:nodoc:  
        # mimick rails 2
        def rescue_from(exception, options = {})
          filter_opts = { :only => options[:only], :except => options[:except] }
          before_filter(filter_opts) do |c|
            c.send :rescue_from_action, exception, options
          end
        end
        
        def no_local_request!
          self.class_eval do
            def local_request?
              false
            end
          end
        end
      end     
      
      protected   
        #
        def rescue_from_action(exception, options = {})
          @rescue_exceptions ||= []
          @rescue_exceptions << [exception, options[:with]]
        end
        
        # Renders a detailed diagnostics screen on action exceptions. 
        # Rails 1.2.6 - ActionPack 1.13.6
        def rescue_action_locally(exception)
          add_variables_to_assigns
          @template.instance_variable_set("@exception", exception)
          @template.instance_variable_set("@rescues_path", File.dirname(rescues_path("stub")))    
          @template.send(:assign_variables_from_controller)

          @template.instance_variable_set("@contents", @template.render_file(template_path_for_local_rescue(exception), false))

#erase_render_results
#        forget_variables_added_to_assigns
#        reset_variables_added_to_assigns
        
          respond_to do |format|
            format.html {
              response.content_type = Mime::HTML
              render_file(rescues_path("layout"), response_code_for_rescue(exception))  
            }            
            format.js { # if request.xhr?            
              rescue_action_locally_as_js(exception)
            }
            # render.xml { }
          end
        end
        
        # call by format.js
        def rescue_action_locally_as_js(exception)
          msg_alert = exception.class.to_s
          if request.parameters['controller']
            msg_alert += ' in ' + request.parameters['controller'].humanize + 'Controller'                  
            msg_alert += '#' + request.parameters['action'] if request.parameters['action']
          end
          msg_alert += "\n" + exception.clean_message
          
          if !exception.application_backtrace.empty? then
            msg_alert += "\n\n" + "Application Trace:\n"
            msg_alert += exception.application_backtrace[0,3].join("\n")
            msg_alert += "\n..." if exception.application_backtrace.size > 3
          end
          
          # redirect to 500.html, also stop javascript request
          content = <<-EOS
window.location.href = #{url_for('/500.html').to_json};
message = #{msg_alert.to_json};
alert(message);
EOS
          response.content_type = Mime::JS
          render_text(content, response_code_for_rescue(exception)) 
          
          # @template.send :evaluate_assigns
          #generator = ActionView::Helpers::PrototypeHelper::JavaScriptGenerator.new(@template) { |page|    
          #page.assign 'content', @template.instance_variable_get("@contents")                                
        end        
        
        # Overwrite to implement public exception handling (for requests answering false to <tt>local_request?</tt>).
        def rescue_action_in_public(exception) #:doc:
          default_action_todo = nil
          if @rescue_exceptions.class <= Array then
            @rescue_exceptions.each do |exception_match, action_todo|
              if exception.class == exception_match then
                send(action_todo) 
                return
              end
              default_action_todo = action_todo if exception_match == :DEFAULT 
            end
          end
          
          # default:
          r_content = ''
          r_status  = 500
          r_file = ''
          case exception
            when ActionController::RoutingError, ActionController::UnknownAction
              r_content = IO.read(File.join(RAILS_ROOT, 'public', r_file = '404.html'))
              r_status = "404 Not Found"
            else
              if default_action_todo then
                send(default_action_todo)
                return
              end
              r_content = IO.read(File.join(RAILS_ROOT, 'public', r_file = '500.html'))
              r_status = "500 Internal Error"
          end
          
          if request.xhr?
            scan_title = r_content.scan(/<head(?:\s*>|s+.*?>).*?<title(?:\s*>|s+.*?>)([^<]*)<\/title\s*>.*?<\/head\s*>/im)
            msg_alert = scan_title.size > 0 ? scan_title.first : r_status
            r_content = <<-EOS
window.location.href = #{url_for(r_file).to_json};
message = #{msg_alert.to_json};
alert(message);
EOS
            response.content_type = Mime::JS
          else
            response.content_type = Mime::HTML
          end
          render_text(r_content, r_status) 
        end
        
      #
    end
  
end
