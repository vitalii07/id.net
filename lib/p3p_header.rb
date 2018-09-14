class P3PHeader
  def initialize(app, options = {})
    @app = app
    @p3p = options[:p3p] || 'CP="ALL DSP COR CURa ADMa DEVa OUR IND COM NAV"'
    @paths_regexp = options[:regex]
  end

  def call(env)
    status, headers, body = @app.call(env)
    req = Rack::Request.new env
    if req.path =~ @paths_regexp
      headers['P3P'] ||= @p3p
    end
    [status, headers, body]
  end
end
