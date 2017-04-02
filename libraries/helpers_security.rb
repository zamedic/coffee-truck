module CoffeeTruck
  module Helpers
    module Security
      extend self


      def getSecurityStats(node)
        http = Net::HTTP.new(node['coffee-truck']['security']['checkmarx']['address'], node['coffee-truck']['security']['checkmarx']['port'])
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(node['delivery']['config']['truck']['security_url'])
        request.add_field('X-IBM-Client-Id', node['coffee-truck']['security']['checkmarx']['key'])
        response = http.request(request)
        Chef::Log.warn(http)
        Chef::Log.warn(response)
        raw = JSON.parse(response.body)
        last_record = raw['value'][-1]

        body = {
            application: node['delivery']['config']['truck']['application'],
            results: {
                high: last_record['High'],
                medium: last_record['Medium'],
                low: last_record['Low']
            }
        }.to_json


      end

    end
  end


  module DSL

    def getSecurityStats(node)
      CoffeeTruck::Helpers::Security.getSecurityStats(node)
    end

  end
end
