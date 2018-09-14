module Idnet::Api::V1::AuthorizationsQueriesCommonMethods
  private

    # @return [void]
    def reject_authorizations_without_score!(authorizations)
      authorizations.reject! { |authorization| authorization.score.nil? }
    end

    # @return [void]
    def sort_authorizations!(authorizations)
      authorizations.sort! { |authorization1, authorization2| authorization2.score.value <=> authorization1.score.value }
    end
end
