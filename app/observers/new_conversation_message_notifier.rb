# Triggers Email notification for Message recipient when new Message is
# created
class NewConversationMessageNotifier < Mongoid::Observer
  observe Idnet::Core::Conversation::Message

  def after_create(message)
    # Because of replication when user sends new message two Messages are
    # created. But we need to send only one notification for Message
    # recipient. Message that belongs to recipient replica of Conversation is
    # always marked as unread. So here we will only react to creation of
    # unread Messages.
    if !message.read? && message.conversation.identity.account.email_notification?
      ConversationMessageMailer.recipient_notification(
        sender_nickname:       message.sender.nickname,
        recipient_identity_id: message.conversation.identity_id,
        sender_pp_id: message.sender.profile_picture.try(:id)
       ).deliver_now
    end
  end
end
