# Activity created by user on feeds#index page
class Idnet::Core::Feed < Idnet::Core::Activity
  belongs_to :author, class_name: "Identity", inverse_of: :own_feeds
  validates :author_id, presence: true
  index({author_id: 1})

  include Idnet::Core::ActivityConcerns::Purging
  include Idnet::Core::ActivityConcerns::Commenting
  include Idnet::Core::ActivityConcerns::Replication
  include Idnet::Core::ActivityConcerns::Spamming

  before_validation :normalize_recipient

  # NOTE not really needed in production because rails knows all
  # children classes and can build proper query including all
  # inherited types, but in development we need to enforce this

  def to_partial_path
    'feed_message'
  end

  private
  def normalize_recipient
    unless self.recipient or self.recipient_id
      self.recipient = self.author
      self.recipient_id = self.author_id
    end
  end
end
