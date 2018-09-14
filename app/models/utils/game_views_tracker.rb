module Utils
  class GameViewsTracker
    include Utils::RedisOptions
    # Every hour data will be stored to db(see workers/game_views_data_store.rb)
    class << self
      def track_view game_id
        redis.zincrby("canvas:views_tracking", 1, game_id)
      end

      def get_views_count game_id
        client = ::Client.find(game_id)
        games_list = redis.zrange("canvas:views_tracking", 0, -1, withscores: true).to_h
        # result will be something like 379.0, so set type explicitly
        (games_list[game_id.to_s].to_i + client.try(:views)).to_i
      end
    end
  end
end
