# Uses SpamCheckServiceConnection to communicate with spam check service
# and updates Activity#spam_state
class Idnet::Core::Activity::SpamManager
  # @param activity [Idnet::Core::Activity]
  def initialize(activity)
    @activity = activity
  end

  # Ckecks if activity is a spam and marks activity accordingly
  #
  # @return (see Idnet::Core::Activity::SpamCheckServiceConnection#spam?)
  def check!
    if @activity.valid?
      @activity.schedule_for_review!
      # Idnet::Core::Activity::SpamCheckServiceConnection.new(@activity).spam?.tap do |spam_check_result|
      #   case spam_check_result
      #   when true
      #     @activity.schedule_for_review!
      #   when false
      #     @activity.mark_as_not_spam!
      #   end
      # end
    end
  end
end
