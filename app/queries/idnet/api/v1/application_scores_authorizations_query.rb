class Idnet::Api::V1::ApplicationScoresAuthorizationsQuery
  include Idnet::Api::V1::AuthorizationsQueriesCommonMethods

  # @param client [Client]
  def initialize(client)
    @client = client
  end

  # @return [Array<Idnet::Core::Authoriztion>] Returns all
  #     {Authorization}s of given {Client}. Omits
  #     Authorizations without scores. Sorts Authorizations by
  #     {Authorization#score} in descending order.
  def fetch
    authorizations = @client.authorizations.authorized.to_a

    reject_authorizations_without_score! authorizations
    sort_authorizations! authorizations

    authorizations
  end
end
