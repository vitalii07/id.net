require 'mailer_utils'

class ConversationMessageMailer < Idnet::Core::UserNotificationsMailer
  default from: "'id.net' <notification@id.net>"
  layout "idnet/core/notification_mails"
  add_template_helper Idnet::Core::MailerHelper

  # @param options [Hash]
  # @option options :sender_nickname [String]
  # @option options :recipient_identity_id [String]
  # @return [MessageDecoy, Mail::Message]
  def recipient_notification(options)
    options            = options.with_indifferent_access
    @sender_nickname   = options[:sender_nickname]
    @conversations_url = conversations_url scope_id: options[:recipient_identity_id]
    @application_name  = 'id.net'
    recipient_identity = Identity.find options[:recipient_identity_id]

    attachments.inline['logo/logo_s.png'] = MailerUtils.logo_small.read

    begin
      if options[:sender_pp_id]
        profile_picture = ProfilePicture.find options[:sender_pp_id]
        attachments.inline['avatar.jpg'] = profile_picture.get_file(:large)
      else
        attachments.inline['avatar.jpg'] = ::File.read(Rails.root.join("app/assets/images/default_picture75.jpg"))
      end
    rescue *Idnet::Core::File::STORAGE_ERRORS
    end
    I18n.with_locale(detect_receiver_language(recipient_identity)) { mail(to: recipient_identity.account.email, subject: t('mailer.conversation_message.title', sender_nickname: @sender_nickname)) }
  end

end
