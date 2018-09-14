require 'spec_helper'

describe NewConversationMessageNotifier do
  describe '#after_create callback' do
    let(:sender_account) { create :confirmed_account }
    let(:sender_identity) { sender_account.identities.first }
    let(:recipient_account) { create :confirmed_account }
    let(:recipient_identity) { recipient_account.identities.first }
    subject do
      sender_identity.start_conversation \
        to:      [recipient_identity.id],
        subject: 'Test subject',
        body:    'Test message'
    end
    let :notification_arguments do
      {
        sender_nickname:       sender_identity.nickname,
        recipient_identity_id: recipient_identity.id,
        sender_pp_id:          nil
      }
    end

    it 'calls ConversationMessageMailer.recipient_notification(...).deliver_now' do
      expect(ConversationMessageMailer).to receive(:recipient_notification).
        with(notification_arguments).
        and_return(double('mailer', deliver_now: true))
      subject
    end

    context 'when recipient Account has Email notification disabled' do
      let(:recipient_account) { create :confirmed_account, email_notification: false }

      it 'does not call ConversationMessageMailer.recipient_notification' do
        expect(ConversationMessageMailer).to_not receive(:recipient_notification)
        subject
      end
    end
  end
end
