module CoffeeTruck
  module Helper
    def gitlog
      cwd = node['delivery']['workspace']['repo']
      command = 'git log --numstat --pretty="%H" --since="1 month ago" | awk \'NF==3 {a[$3]+=$1+$2} END {for (i in a) printf("%5d\t%s\n", a[i], i)}\' | grep .java$ | sort -k1 -rn'
      log = `cd #{cwd} && #{command}`
      log.split("\n").map { |line| line.strip.split("\t").reverse }.to_h
    end

    def sonarmetrics
      cwd = node['delivery']['workspace']['repo']
      command = "curl -X GET '#{node['delivery']['config']['sonar']['host']}/api/resources?resource=#{node['delivery']['config']['sonar']['resource']}&metrics=ncloc,coverage,tests,test_errors,test_failures'"
      raw = JSON.parse `cd #{cwd} && #{command}`
      metrics = raw[0]['msr'].map do |msr|
        [msr['key'], msr['val']]
      end.to_h
      {
        lines: metrics['ncloc'],
        coverage: metrics['coverage'],
        unit: {
          total: metrics['tests'],
          errors: metrics['test_errors'],
          failures: metrics['test_failures']
        },
        integration: {
        },
        acceptance: {
        }
      }
    end
  end
end