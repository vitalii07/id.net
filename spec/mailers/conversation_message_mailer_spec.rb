require 'spec_helper'

describe ConversationMessageMailer do
  describe '#recipient_notification' do
    let(:sender_account) { create :confirmed_account }
    let(:sender_identity) { sender_account.identities.first }
    let(:recipient_account) { create :confirmed_account }
    let(:recipient_identity) { recipient_account.identities.first }
    let(:sender_email) { 'notification@id.net' }
    let :conversation do
      sender_identity.start_conversation \
        to:      [recipient_identity.id],
        subject: 'Test subject',
        body:    'Test message'
    end
    let :notification_arguments do
      {
        sender_nickname:       sender_identity.nickname,
        recipient_identity_id: recipient_identity.id,
      }
    end
    let :expected_conversations_url do
      conversations_url \
        scope_id: recipient_identity.id,
        host:     Idnet.config.application.host
    end
    subject { described_class.recipient_notification(notification_arguments).deliver_now }

    shared_examples_for 'successful message delivery' do
      it 'delivers message' do
        expect { subject }.to change ActionMailer::Base.deliveries, :length
      end

      it 'sets options of Email' do
        subject
        expect(last_email.from).to eq [sender_email]
        expect(last_email.to).to eq [recipient_account.email]
        expect(last_email.subject).to eq "Private message from #{sender_identity.nickname}"
      end

      it 'renders nickname and conversation link in message body' do
        subject
        expect(last_email.text_part.body).to have_content sender_identity.nickname
        expect(last_email.text_part.body).to have_content expected_conversations_url
        expect(last_email.html_part.body).to have_content sender_identity.nickname
        expect(last_email.html_part.body).to have_css "a[href='#{expected_conversations_url}']"
      end
    end

    it_behaves_like 'successful message delivery'

    context 'when String keys are supplied' do
      let :notification_arguments do
        {
          'sender_nickname'       => sender_identity.nickname,
          'recipient_identity_id' => recipient_identity.id,
        }
      end

      it_behaves_like 'successful message delivery'
    end
  end
end
