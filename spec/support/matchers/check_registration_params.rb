RSpec::Matchers.define :match_attributes_of do |affiliate|
  match do |params|
    params = params.with_indifferent_access
    params[:consumer] == affiliate.client.id &&
    params[:client_name] == affiliate.display_name &&
    params[:redirect_uri] == affiliate.redirect_uri &&
    params[:link] == affiliate.redirect_uri &&
    params[:prefill].present? &&
    params[:prefill][:alternate] == affiliate.display_name &&
    params[:prefill][:alternate_privacy_url] == affiliate.privacy_policy_uri &&
    params[:prefill][:alternate_tos_url] == affiliate.terms_of_service_uri
  end

  description do
    "matches account registration params with affiliate attributes"
  end
end