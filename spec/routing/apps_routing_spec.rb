require 'spec_helper'

describe 'apps.id.net routing process' do
  let(:game) { create :game }

  it 'routes apps.id.net/game-slug to canvas#show' do
    assert_routing "http://apps.lvh.me/#{game.slug}",
      { subdomain: 'apps', controller: "canvas", action: "show", id: game.slug}
  end
end
