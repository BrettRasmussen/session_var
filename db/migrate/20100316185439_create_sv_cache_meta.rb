class CreateSvCacheMeta < ActiveRecord::Migration
  def self.up
    create_table :sv_cache_meta do |t|
      t.string :page_url, :sv_cache_key
      t.datetime :expires_at
    end
  end

  def self.down
    drop_table :sv_cache_meta
  end
end
