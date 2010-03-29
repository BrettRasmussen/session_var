module SessionVarTags
  include Radiant::Taggable
  
  tag "if_session_var" do |tag|
    session_var = tag.attr['name']
    session_var_value = tag.attr['value']
    if @request.session[session_var.to_s] == session_var_value ||
    @request.session[session_var.to_sym] == session_var_value
      tag.expand
    end
  end
end
