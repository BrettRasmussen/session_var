module SessionVarPageExtensions
  def self.included(base)
    base.class_eval do
      after_save :clear_self_from_sv_cache
      alias_method_chain :process, :session_var_caching
    end
  end

  # Check if the desired page is already stored in the cache.  If so, use it; if
  # not, store it and use it.
  def process_with_session_var_caching(request, response)
    @request, @response = request, response
    return process_without_session_var_caching(request, response) if !cache?

    # Return what's in the cache or set it up in the first place.
    if cached_body
      if layout
        content_type = layout.content_type.to_s.strip
        @response.headers['Content-Type'] = content_type unless content_type.empty?
      end
      headers.each { |k,v| @response.headers[k] = v }
      @response.body = cached_body
      @response.status = response_code
    else
      process_without_session_var_caching(request, response)
      @response.body.gsub!(/<SV_TIMESTAMP>/, Time.now.to_s) # just for testing purposes
      sv_cache_current
    end

    @response.status
  end

  private

  # Returns the sv_cache_key, an MD5 hash (hexdigest) of a string comprised of
  # the url and key=value pairs from the session variables reported by
  # set_session_vars, all semicolon-delimited.  For example, a given set of
  # session variables might cause the following string to be created internally:
  #   "/products;language=en_gb;theme=BlueGreen"
  # In that case, this method would return the MD5 hash of that string:
  #   "95a2325f2882a6180356241535c940c1"
  def sv_cache_key
    return @sv_cache_key if @sv_cache_key
    sv_cache_key = self.url
    session_vars = handle_sv_http_data
    session_vars = session_vars | set_session_vars(@request)
    session_vars.each {|var| sv_cache_key << ";#{var.to_s}=#{@request.session[var].to_s}"}
    @sv_cache_key = Digest::MD5.hexdigest(sv_cache_key)
  end

  # Sets any session variables that come in as sv[key]=val pairs in the http
  # params.  If Radiant::Config["session_var.valid_http_data"] is a non-empty
  # list of keys, ignores any keys not found therein.  Returns the list of valid
  # keys.
  def handle_sv_http_data
    sv_pairs = params[:sv] || {}
    if !valid_sv_http_data.empty?
      sv_pairs.keys.each {|k| sv_pairs.delete(k) if !valid_sv_http_data.has_key?(k)}
    end
    sv_pairs.each do |k,v|
      if valid_sv_http_data.has_key?(k) && !valid_sv_http_data[k].empty?
        next if !valid_sv_http_data[k].include?(v)
      else
        next if v !~ sv_http_value_regex
      end
      @request.session[k] = v
    end

    # return all valid keys whether used by this method or not
    sv_pairs.keys | valid_sv_http_data.keys
  end

  # Returns an array of the valid_http_keys list from Radiant::Config.
  def valid_sv_http_data
    return @valid_sv_http_data if @valid_sv_http_data
    @valid_sv_http_data = {}
    Radiant::Config['session_var.valid_http_data'].to_s.scan(/(\w+)(\[[^\]]*\])?,?\s*/) do |match|
      values = match[1].to_s.gsub(/(^\[|\]$)/, "").split('|')
      @valid_sv_http_data[match[0]] = values
    end
    @valid_sv_http_data
  end

  # Returns a regular expression to match against any http sv[] values.
  # Defaults to just word characters but can be overridden in
  # Radiant::Config['session_var.http_value_regex'].
  def sv_http_value_regex
    return @sv_http_value_regex if @sv_http_value_regex
    @sv_http_value_regex = if !Radiant::Config['session_var.http_value_regex'].to_s.empty?
      eval(Radiant::Config['session_var.http_value_regex'])
    else
      /^\w*$/
    end
  end

  # If there is a valid cache entry with a valid matching SvCacheMeta entry,
  # returns the response body from the cache. If not, returns nil.
  def cached_body
    return @cached_body if @cached_body
    cached_body = $sv_cache.get(sv_cache_key)
    meta_data = SvCacheMeta.find_by_sv_cache_key(sv_cache_key)
    if cached_body && meta_data && meta_data.expires_at > Time.now
      @cached_body = cached_body
      return cached_body
    else
      $sv_cache.delete(sv_cache_key)
      meta_data.destroy if meta_data
      return nil
    end
  end

  # Adds the current page with the current session variables to the cache,
  # including setting up a SvCacheMeta entry.
  def sv_cache_current
    $sv_cache.set(sv_cache_key, @response.body)
    exp_minutes = (defined? SESSION_VAR_CACHE_EXPIRATION_MINUTES) ? SESSION_VAR_CACHE_EXPIRATION_MINUTES : 5
    SvCacheMeta.create(
      :page_url => self.url,
      :sv_cache_key => sv_cache_key,
      :expires_at => Time.now + exp_minutes.minutes
    )
  end

  # Removes all entries from the session_var cache whose url is the same as the
  # current page's.
  def clear_self_from_sv_cache
    cache_entries = SvCacheMeta.find(:all, :conditions => ["page_url = ?", self.url])
    cache_entries.each do |ce|
      $sv_cache.delete(ce.sv_cache_key)
      ce.destroy
    end
  end
end
