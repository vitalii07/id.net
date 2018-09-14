class ClientCacheObserver < Mongoid::Observer
  observe Client

  def self.cache_path client_slug, proto='http', header_present=true
    ['canvas', proto, client_slug, header_present].join(':')
  end

  def after_update client
    return unless client.app?
    ['http', 'https'].each do |protocol|
      Rails.cache.delete self.class.cache_path(client.slug, protocol)
    end
  end
end
