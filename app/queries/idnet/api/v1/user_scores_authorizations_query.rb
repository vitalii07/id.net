class Idnet::Api::V1::UserScoresAuthorizationsQuery
  include Idnet::Api::V1::AuthorizationsQueriesCommonMethods

  # @param authorization [Idnet::Core::Authoriztion]
  def initialize(authorization)
    @authorization = authorization
  end

  # @return [Array<Idnet::Core::Authoriztion>] Returns given
  #     {Authorization} + Authorizations of friends. Omits
  #     Authorizations without scores. Sorts Authorizations by
  #     {Authorization#score} in descending order.
  def fetch
    authorizations = [@authorization]

    authorizations += friends_authorizations

    reject_authorizations_without_score! authorizations
    sort_authorizations! authorizations

    authorizations
  end

  private

    # @return [Array<Authorization>] Returns an Array of
    #     Authorizations of friends
    def friends_authorizations
      Authorization.where(
        client_id: @authorization.client.id,
        :identity_id.in => @authorization.identity.friends
      ).to_a
    end
end
