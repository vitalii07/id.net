module Utils
  class ActivePlayersTracker
    include Utils::RedisOptions

    PREFIX = 'minuteman'

    class << self
      def track_player user_id, game_id
        minuteman.track(build_event(game_id), user_id.to_i)
        tracking_redis.expire build_mm_hour_key(Time.now.utc, game_id), 3*3600
        tracking_redis.expire build_mm_key(Time.now.utc, game_id), 3*3600
      end

      def get_players_count game_id
        minuteman.hour(build_event(game_id), 1.hour.ago.utc).length
      rescue Timeout::Error => e
        Rails.logger.error("Could not get active players count, retrying once: #{e}")
        sleep rand(0.01..0.09) # give redis a second chance after tiny delay
        minuteman.hour(build_event(game_id), 1.hour.ago.utc).length
      end

      private

      def build_mm_key(time, game_id)
        # in order to set expiration time, we need to find key name, built by minuteman
        # https://github.com/elcuervo/minuteman/blob/master/lib/minuteman/time_span.rb#L32
        [PREFIX, build_event(game_id), build_date(time).join("-")].join("_")
      end

      def build_mm_hour_key(time, game_id)
        [PREFIX, build_event(game_id), build_date(time, '00').join("-")].join("_")
      end

      def build_event(game_id)
        "canvas:players_tracking:#{game_id}"
      end

      def build_date(time, minute_key = '%M')
        event_time = time.kind_of?(Time) ? time : Time.parse(time.to_s)
        format_date = event_time.strftime("%Y-%m-%d")
        format_time = event_time.strftime("%H:#{minute_key}")
        ["#{format_date} #{format_time}"]
      end
    end
  end
end
