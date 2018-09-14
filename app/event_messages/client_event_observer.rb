module ClientEventObserver
  USER_SIGNUP_AGENT = 'user.signup.agent'
  CERTIFICATION_SUBMITTED_AGENT = 'certification.submitted.agent'
  AGENT_EVENTS = [USER_SIGNUP_AGENT, CERTIFICATION_SUBMITTED_AGENT]

  USER_SIGNUP = 'user.signup'
  USER_CONFIRMED_EMAIL = 'user.confirmed_email'
  USER_CONFIRMED_PHONE = 'user.confirmed_phone_number'

  CERTIFICATION_SUBMITTED = 'certification.submitted'
  CERTIFICATION_CONFIRMED = 'certification.confirmed'
  CERTIFICATION_REJECTED = 'certification.rejected'
  USER_EVENTS = [USER_SIGNUP, USER_CONFIRMED_EMAIL, USER_CONFIRMED_PHONE,
                 CERTIFICATION_SUBMITTED, CERTIFICATION_CONFIRMED, CERTIFICATION_REJECTED]

  EVENT_MESSAGES = USER_EVENTS + AGENT_EVENTS

  EVENT_MESSAGES.map do |event|
    ActiveSupport::Notifications.subscribe(event, ClientEventSubscriber.new)
  end

  def push_event_to_client(*args)
    ActiveSupport::Notifications.instrument(*args)
  end
end

