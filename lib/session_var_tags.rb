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

  tag "session_var" do |tag|
    tag.expand
  end

  tag "session_var:switcher" do |tag|
    content = tag.expand
    type = tag.attr['type'] || "dropdown"
    action = tag.attr['url'] || @request.env["REQUEST_PATH"]
    case tag.attr['type']
    when "dropdown":
      content = <<-EOS
        <form style="display:inline" action="#{action}" method="post">
          <select name="#{name}">
            #{content}
          </select>
        </form>
      EOS
    when "links":
  end
end
