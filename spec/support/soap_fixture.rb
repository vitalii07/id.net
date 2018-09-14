class SoapFixture

  class << self

    def [](file)
      fixtures[file] ||= read_file(file)
    end

    def response file, options={}
      body = self[file]
      opts = { code: 200, headers: {}, body: body }.merge(options)
      HTTPI::Response.new opts[:code], opts[:headers], opts[:body]
    end

    def body(file)
      @response_hash ||= {}
      @response_hash[file] ||= Nori.parse(self[file])[:envelope][:body]
    end

  private

    def fixtures
      @fixtures ||= {}
    end

    def read_file(file)
      path = File.expand_path "../../fixtures/#{file}.xml", __FILE__
      raise ArgumentError, "Unable to load: #{path}" unless File.exist? path
      File.read path
    end

  end
end
