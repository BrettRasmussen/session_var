require 'memcached'

class SessionVarMemcache
  def initialize(host="localhost", port=11211)
    @memcache = Memcached.new("#{host}:#{port}")
  end

  def get(key)
    @memcache.get(key)
  rescue Memcached::NotFound
    nil
  end

  def set(key, value)
    @memcache.set(key, value)
  end

  def delete(key)
    @memcache.delete(key)
  rescue Memcached::NotFound
    nil
  end
end
