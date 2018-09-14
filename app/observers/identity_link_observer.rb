class IdentityLinkObserver < Mongoid::Observer
  observe "IdentityLink"

  def after_create identity_link
    unless identity_link.mirrored? || identity_link.receiver.account.email_notification == false
      send_email(identity_link.receiver, identity_link.requester)
    end
  end

  private

  def send_email receiver, sender
     client = 'id.net'
     Idnet::Core::Notifications::ContactRequestMailer.on_follow(receiver, sender, client).deliver_now
  end
end
