class Dialogs::LeaderboardController < Dialogs::BaseController
  skip_before_filter :authenticate_account_for_sdk!, only: :index

  def index
    # test call, to make sure client was found
    client

    # took this part from lib/controllers/api/leaderboard.rb
    # TODO: refactoring
    @scores = client.scores.desc(:value).limit(25)
    case params[:period]
    when "day"
      @scores = @scores.where(:updated_at.gt => 1.day.ago)
    when "week"
      @scores = @scores.where(:updated_at.gt => 1.week.ago)
    when "month"
      @scores = @scores.where(:updated_at.gt => 1.month.ago)
    end

    @authorizations = @scores.map(&:authorization).compact

    if params[:country].present?
      # pure ruby: workaround for missing JOINs
      @authorizations.select! { |auth| auth.identity.country == params[:country] }
    end

    @authorizations.map!{|auth| [auth.identity.nickname, auth.score.value]}
  end

  private

  def check_params
    unless params[:redirect_uri]
      render_error :invalid_request, status: 400
    end
  end
end