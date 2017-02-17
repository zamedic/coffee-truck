module CoffeeTruck
  module Helpers
    module Security
      extend self


      def getSecurityStats(node)
        http = Net::HTTP.new('10.144.20.96','443')
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(node['delivery']['config']['truck']['security_url'])
        request.add_field('X-IBM-Client-Id','945b4987-8857-43a1-8038-bf4753cc6b7f')
        response = http.request(request)
        Chef::Log.warn(http)
        Chef::Log.warn(response)
        raw = JSON.parse(response)
        last_record = raw['value'][-1]

        body = {
            application: node['delivery']['config']['truck']['application'],
            results: {
                high: last_record['High'],
                medium: last_record['Medium'],
                low: last_record['Low']
            }
        }.to_json

        uri = URI('http://spambot.standardbank.co.za/events/security-results')
        req = Net::HTTP::Post.new(uri)
        req.body = body
        req.content_type = 'application/json'

        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end
      end

    end
  end



  module DSL

    def getSecurityStats(node)
      CoffeeTruck::Helpers::Security.getSecurityStats(node)
    end

  end
end
