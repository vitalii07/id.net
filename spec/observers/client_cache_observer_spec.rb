require 'spec_helper'

describe ClientCacheObserver do
  describe 'swiping cache' do
    let(:client) { create :game }
    let(:client_cache_path) { ClientCacheObserver.cache_path(client.slug) }
    let(:test_page) { Forgery(:lorem_ipsum).text(:characters, 150) }

    before do
      Rails.cache.write(client_cache_path, test_page)
    end

    it 'should swipe cache after client modification' do
      page = Rails.cache.fetch(client_cache_path)
      page.should == test_page
      client.link = 'http://y8.com'
      client.save
      page = Rails.cache.fetch(client_cache_path)
      page.should be_nil
    end
  end
end
