module CoffeeTruck
  module Helpers
    module Security
      include Chef::Mixin::ShellOut
      extend self


      def getSecurityStats()
        require 'ntlm/http'
        http = Net::HTTPS.new('psdc-pa001gth1v.za.sbicdirectory.com')
        request = Net::HTTPS::Get.new('/Cxwebinterface/odata/v1/Projects?$expand=LastScan&$orderby=LastScan/RiskScore%20desc&$top=2')
        request.ntlm_auth('c1592023', '', 'trendweb')
        response = http.request(request)
        Chef::Log.warn(response)
      end

    end
  end

  module DSL

    def getSecurityStats()
      CoffeeTruck::Helpers::Security.getSecurityStats()
    end

  end
end
