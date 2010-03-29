class SvCacheMeta < ActiveRecord::Base
  set_table_name "sv_cache_meta"
  validates_presence_of :page_url, :expires_at
  validates_uniqueness_of :sv_cache_key
end
