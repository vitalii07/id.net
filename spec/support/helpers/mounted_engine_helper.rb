module MountedEngineHelper
  def process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
    if parameters.is_a?(Hash) && ::RSpec.configuration.use_route
      parameters.reverse_merge!(use_route: RSpec.configuration.use_route)
    end
    super
  end
end
RSpec::Core::Configuration.add_setting(:use_route)

