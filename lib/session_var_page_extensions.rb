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
      @response.body.gsub!(/<<SV_TIMESTAMP>>/, Time.now.to_s) # just for testing purposes
      cache_current
    end

    @response.status
  rescue => e
    logger.error
    logger.error "Unable to use page cache for page '#{request.path}', so doing full render. Details follow:"
    logger.error "#{e.class}: #{e}"
    logger.error

    process_without_session_var_caching(request, response)
  end

  private

  # Returns the sv_cache_key, a string comprised of the url and key=value pairs
  # from the session variables reported by set_session_vars, all
  # semicolon-delimited.  For example, a given set of session variables might
  # cause the following string to be created internally:
  #   "/products;language=en_gb;theme=BlueGreen"
  # Note that whatever cache class you're using may well hash this string
  # before storing it. If not, it's a good idea do so yourself.
  def sv_cache_key
    return @sv_cache_key if @sv_cache_key
    sv_cache_key = self.url
    session_vars = set_session_vars(@request) # used by sv_cache_key
    session_vars.each {|var| sv_cache_key << ";#{var.to_s}=#{@request.session[var].to_s}"}
    @sv_cache_key = sv_cache_key
  end

  # If there is a valid cache entry with a valid matching SvCacheMeta entry,
  # returns the response body from the cache. If not, returns nil.
  def cached_body
    return @cached_body if @cached_body
    cached_body = $sv_cache.get(sv_cache_key)
    meta_data = SvCacheMeta.find(:first, :conditions => ["sv_cache_key = ?", sv_cache_key])
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
  def cache_current
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
