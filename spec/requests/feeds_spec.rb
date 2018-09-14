require 'spec_helper'

describe 'Feeds' do
  shared_examples_for 'Activity descendants renderer' do
    let(:account) { create :confirmed_account }
    let(:client) { create :client }
    before { login_as account }

    context 'when Feed is present' do
      let! :activity do
        create :feed, recipient: account.identities.first
      end

      it 'renders Feed' do
        subject

        within '.feed' do
          expect(page).to have_content activity.author.display_title
          expect(page).to have_content activity.message
        end
      end
    end

    context 'when SiteFeed is present' do
      let! :activity do
        create :site_feed, recipient: account.identities.first
      end

      it 'renders SiteFeed' do
        subject

        within '.feed' do
          expect(page).to have_content activity.author.display_title
          expect(page).to have_content activity.message
        end
      end
    end

    context 'when SiteComment is present' do
      let! :activity do
        create :site_comment,
          recipient: account.identities.first,
          app:       client
      end

      it 'renders SiteComment' do
        subject

        within '.feed' do
          expect(page).to have_content activity.author.display_title
          within '.feed-content-image.left' do
            expect(find('a')[:href]).to eq activity.url
            expect(first('a > img')[:src]).to eq activity.client.image_url
          end
          expect(page).to have_content activity.message
        end
      end
    end

    context 'when AppFeed is present' do
      let! :activity do
        create :app_feed,
          recipient: account.identities.first,
          app_id:    client.id
      end

      it 'renders AppFeed' do
        subject

        within '.feed' do
          expect(first('img')[:src]).to eq client.image_url
          expect(page).to have_content client.display_name
          expect(page).to have_content activity.caption
          expect(page).to have_content activity.message
          expect(find('.feed-content-image.left a')[:href]).to eq activity.url
          expect(find('a > img')[:src]).to eq activity.picture
        end
      end
    end

    context 'when ApplicationRequest is present' do
      let! :activity do
        origin = create :application_request,
          author:     create(:identity),
          recipients: [account.identities.first.id],
          client:     client
        origin.replicates.first
      end

      it 'renders ApplicationRequest' do
        subject

        within '.feed' do
          expect(page).to have_content activity.author.display_title
          expect(page).to have_content client.display_name
          expect(page).to have_content activity.message
          expect(find_link('Accept')[:href]).to eq visit_identities_path(next: activity.redirect_uri + "?request_id=#{activity.origin_id}", client_id: activity.client_id, response_type: 'code', pre_select: activity.recipient_id)
          expect(find_link("trash-#{activity.id}")[:href]).to eq trash_feed_path activity
        end
      end
    end
  end

  describe '#index' do
    subject { visit feeds_path }

    it_behaves_like 'Activity descendants renderer'
  end

  describe '#show' do
    subject { visit feed_path activity }

    it_behaves_like 'Activity descendants renderer'
  end
end
