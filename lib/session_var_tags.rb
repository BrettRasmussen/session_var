module SessionVarTags
  include Radiant::Taggable
  
  tag "if_session_var" do |tag|
    session_var = tag.attr['name']
    session_var_value = tag.attr['value']
    if @request.session[session_var.to_s] == session_var_value
      tag.expand
    end
  end

  tag "session_var" do |tag|
    tag.expand
  end

  tag "session_var:self" do |tag|
    @request.path
  end

  tag "session_var:switcher" do |tag|
    attrs = tag.attr.dup
    tag.locals.name = attrs.delete('name')
    tag.locals.session_val = @request.session[tag.locals.name]
    tag.locals.switcher_type = attrs.delete('type') || "dropdown"
    tag.locals.action = attrs.delete('url') || @request.path

    content = tag.expand
    options_start = content.index("<SV_OPT>")
    options_end = content.rindex("</SV_OPT>")+9
    leading_content = content[0...options_start]
    options_block = content[options_start...options_end].gsub(/<\/?SV_OPT>/, "")
    trailing_content = content[options_end..-1]
    content.gsub!(/<\/?SV_OPT>/, "")

    js_submit = attrs.delete("js_submit") == "false" ? "" : %{onChange="this.form.submit();"}

    attrs = attrs.inject("") {|m,kv| m += %{ #{kv[0]}="#{kv[1]}"}; m}

    case tag.locals.switcher_type
      when "dropdown"
        <<-EOS
          <form action="#{tag.locals.action}" method="post" style="display:inline" #{attrs}>
              #{leading_content}
            <select name="sv[#{tag.locals.name}]" #{js_submit}>
              #{options_block}
            </select>
              #{trailing_content}
          </form>
        EOS
      when "links"
        content
      else
        <<-EOS
          Invalid session_var:switcher type '#{tag.locals.switcher_type}'.
          Must be either 'dropdown' or 'links'.
        EOS
    end
  end

  tag "session_var:switcher:option" do |tag|
    attrs = tag.attr.dup
    tag.locals.option_val = attrs.delete('value')
    tag.locals.option_attrs = attrs.inject("") {|m,kv| m += %{ #{kv[0]}="#{kv[1]}"}; m}
    content = tag.expand
    case tag.locals.switcher_type
      when "dropdown"
        sel_text = tag.locals.session_val == tag.locals.option_val ? " selected" : ""
        content = %{<option value="#{tag.locals.option_val}"#{sel_text}} +
                  %{ #{tag.locals.option_attrs}>#{content.strip}</option>}
      when "links"
        if !content.strip.start_with?("<a")
          content = sv_option_link(
            tag.locals.action,
            tag.locals.name,
            tag.locals.option_val,
            content,
            tag.locals.option_attrs
          )
        end
    end
    "<SV_OPT>#{content}</SV_OPT>"
  end

  tag "session_var:switcher:option:unselected" do |tag|
    if tag.locals.session_val != tag.locals.option_val
      sv_selected_or_unselected_option(tag)
    end
  end

  tag "session_var:switcher:option:selected" do |tag|
    if tag.locals.session_val == tag.locals.option_val
      sv_selected_or_unselected_option(tag)
    end
  end

  tag "session_var:timestamp" do |tag|
    "<SV_TIMESTAMP>"
  end

  tag "session_vars" do |tag|
    output = "----------<br/>"
    @request.session.each {|k,v| output += "#{k}: #{v}<br/>"}
    output += "----------<br/>"
  end


  private

  def sv_selected_or_unselected_option(tag)
    case tag.locals.switcher_type
      when "dropdown"
        tag.expand
      when "links"
        sv_option_link(
          tag.locals.action,
          tag.locals.name,
          tag.locals.option_val,
          tag.expand,
          tag.locals.option_attrs
        )
    end
  end

  def sv_option_link(action, name, option_val, content, attrs)
    %{<a href="#{action}?sv[#{name}]=#{option_val}" #{attrs}>#{content}</a>}
  end
end
