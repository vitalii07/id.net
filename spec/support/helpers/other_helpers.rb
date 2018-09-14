module OtherHelpers
  extend ActiveSupport::Concern

  included do
    let(:parsed_response) { JSON.parse subject.body }
    let(:last_email) { ActionMailer::Base.deliveries.last }
    let(:devise_sender_email) { Devise.mailer_sender.match(/<([^>]+)>/)[1] }
  end

  def reset_email
    ActionMailer::Base.deliveries = []
  end
end
