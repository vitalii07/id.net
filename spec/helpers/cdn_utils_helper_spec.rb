require 'spec_helper'

describe CdnUtilsHelper do
  describe '#scdn_url' do
    it 'accepts url starting with slash' do
      expect(helper.scdn_url('/some/stuff')).to eq('https://scdn.id.lvh.me/some/stuff')
    end

    it 'accepts url starting without slash' do
      expect(helper.scdn_url('some/stuff')).to eq('https://scdn.id.lvh.me/some/stuff')
    end

    it "doesn't crash for null input" do
      expect(helper.scdn_url(nil)).to eq('https://scdn.id.lvh.me/image_missing.jpg')
    end
  end
end
