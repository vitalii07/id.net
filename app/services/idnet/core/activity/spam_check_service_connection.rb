# Communicates with spam check service (Akismet)
class Idnet::Core::Activity::SpamCheckServiceConnection
  include Rakismet::Model

  # Attributes that Rakismet relies on:
  # author        : name submitted with the comment
  # author_url    : URL submitted with the comment
  # author_email  : email submitted with the comment
  # comment_type  : Defaults to comment but you can set it to trackback, pingback, or something more appropriate
  # content       : the content submitted
  # permalink     : the permanent URL for the entry the comment belongs to
  # user_ip       : IP address used to submit this comment
  # user_agent    : user agent string
  # referrer      : referring URL (note the spelling)

  rakismet_attrs \
    author:       proc { @activity.author.nickname },
    author_email: proc { @activity.author.account.email },
    content:      proc { @activity.message },
    permalink:    proc { @activity['url'] }, # fixing activities that do not have url (like feed from id.net wall)
    user_ip:      :request_ip,
    user_agent:   proc { @activity.request_information.try :user_agent },
    referrer:     proc { @activity.request_information.try :referer }

  # @param activity [Idnet::Core::Activity]
  def initialize(activity)
    @activity = activity
  end

  # @return [Boolean, nil] Returns Boolean if request was successful. nil - if
  #     there was an error.
  def spam?
    return unless request_ip.present?
    result = super
    if spam_check_successful?
      result
    end
  end

  # @return [Boolean, nil] Returns nil when there was no spam check performed
  #     yet
  def spam_check_successful?
    if akismet_response.present?
      akismet_response.in? %w(true false)
    end
  end

  def spam!
    # super
    @activity.set_moderation_lock
    @activity.spam_state_event = :mark_as_spam
    @activity.moderated = true
    @activity.save!(validate: false).tap { @activity.__elasticsearch__.index_document }
  end

  def ham!
    # super
    @activity.set_moderation_lock
    @activity.spam_state_event = :mark_as_not_spam
    @activity.moderated = true
    @activity.save!(validate: false).tap { @activity.__elasticsearch__.index_document }
  end

  private

  def request_ip
    @activity.request_information.try :ip
  end
end
