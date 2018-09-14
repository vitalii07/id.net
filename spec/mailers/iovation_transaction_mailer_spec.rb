require 'spec_helper'

describe IovationTransactionMailer do
  describe '#report' do
    let(:account) { create :confirmed_account }
    let(:sender_account) { create :antifraud_moderator }
    let(:iovation_transaction) { create :iovation_transaction, account: account }
    let(:iovation_transaction_url) { "#{Idnet.config.iovation.admin_host}/admin/trackingNumberDetails/load/#{iovation_transaction.tracking_number}" }
    subject { described_class.report(sender_account.email, iovation_transaction.id.to_s).deliver_now }

    it 'delivers Email' do
      expect { subject }.to change(ActionMailer::Base.deliveries, :length).from(0).to 1
    end

    it 'sets options of an Email' do
      subject
      expect(last_email.from).to eq [sender_account.email]
      expect(last_email.to).to eq ['mamaury@id.net']
      expect(last_email.subject).to match /suspicious.*transaction/i
    end

    it 'renders information about IovationTransaction in Email body' do
      subject
      expect(last_email.text_part.body).to have_content iovation_transaction.id.to_s
      expect(last_email.text_part.body).to have_content iovation_transaction.tracking_number
      expect(last_email.text_part.body).to have_content admin_transaction_url iovation_transaction
      expect(last_email.text_part.body).to have_content iovation_transaction_url

      expect(last_email.html_part.body).to have_content iovation_transaction.id.to_s
      expect(last_email.html_part.body).to have_content iovation_transaction.tracking_number
      expect(last_email.html_part.body).to have_css "a[href='#{admin_transaction_url iovation_transaction}']"
      expect(last_email.html_part.body).to have_css "a[href='#{iovation_transaction_url}']"
    end

    context 'when #tracking_number is nil' do
      let(:iovation_transaction) { create :iovation_transaction, account: account, tracking_number: nil }

      it 'delivers Email' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :length).from(0).to 1
      end

      it 'renders information about IovationTransaction in Email body' do
        subject
        expect(last_email.text_part.body).to have_content iovation_transaction.id.to_s
        expect(last_email.text_part.body).to have_content admin_transaction_url iovation_transaction
        expect(last_email.text_part.body).to have_content 'No tracking number'

        expect(last_email.html_part.body).to have_content iovation_transaction.id.to_s
        expect(last_email.html_part.body).to have_css "a[href='#{admin_transaction_url iovation_transaction}']"
        expect(last_email.html_part.body).to have_content 'No tracking number'
      end
    end
  end
end
