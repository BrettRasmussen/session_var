class SessionVarMemcache
  def initialize(*args)
    require 'memcached'
    @memcache = Memcached.new(*args)
  end

  def get(key)
    first_attempt = true
    begin
      @memcache.get(key)
    rescue Memcached::NotFound
      nil
    rescue => e
      if first_attempt
        first_attempt = false
        @memcache.reset
        retry
      end
      raise e
    end
  end

  def set(key, value)
    first_attempt = true
    begin
      @memcache.set(key, value)
    rescue => e
      if first_attempt
        first_attempt = false
        @memcache.reset
        retry
      end
      raise e
    end
  end

  def delete(key)
    first_attempt = true
    begin
      @memcache.delete(key)
    rescue Memcached::NotFound
      nil
    rescue => e
      if first_attempt
        first_attempt = false
        @memcache.reset
        retry
      end
      raise e
    end
  end
end
