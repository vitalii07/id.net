require 'spec_helper'

describe RequestTimingMiddleware do
  let(:app) { ->(env) { [200, env, 'app'] } }
  let(:middleware) { RequestTimingMiddleware.new(app) }
  let(:request_options) do
    {
      'action_dispatch.request.path_parameters' => {
        controller: 'test',
        action: 'hello'
      }
    }
  end

  it 'times requests' do
    expect(Stats).to receive(:timing).with('request.test.hello.time', kind_of(Numeric))
    code, _ = middleware.call env_for('https://www.id.net/test/hello', request_options)
    code.should == 200
  end

  it 'times requests when action_dispatch.request.path_parameters missing' do
    expect(Stats).to receive(:timing).with('request.unknown_controller.test_hello.time', kind_of(Numeric))
    code, _ = middleware.call env_for('https://www.id.net/test/hello')
    code.should == 200
  end
end

def env_for(url, opts = {})
  Rack::MockRequest.env_for(url, opts)
end
