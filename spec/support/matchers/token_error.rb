RSpec::Matchers.define :return_error do |error|
  match do |response|
    response.status == 401 &&
    error_description(response) == error
  end

  failure_message_for_should do |response|
    "expected that response.status #{response.status} should == 401
     and body.error_description #{error_description(response)} should == #{error}"
  end

  description do
    "checks if API error is returned"
  end

  def error_description response
    JSON.parse(response.body)['error_description']
  end
end
