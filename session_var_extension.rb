# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class SessionVarExtension < Radiant::Extension
  version "1.0"
  description "Renders and caches multiple variations of the same page depending on session variables."
  url "http://yourwebsite.com/session_var"
  
  def activate
    Page.send :include, SessionVarPageExtensions
    Page.send :include, SessionVarTags
    $sv_cache = SessionVarMemcache.new(['localhost:11211'], :prefix_key=>"sv:") if !$sv_cache
  end
  
  def deactivate
  end
end
