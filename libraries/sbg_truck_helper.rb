module SbgTruck
  module Helper
    def gitlog
      cwd = node['delivery']['workspace']['repo']
      command = 'git log --numstat --pretty="%H" --since="1 month ago" | awk \'NF==3 {a[$3]+=$1+$2} END {for (i in a) printf("%5d\t%s\n", a[i], i)}\' | grep .java$ | sort -k1 -rn'
      log = `cd #{cwd} && #{command}`
      log.split("\n").map { |line| line.strip.split("\t").reverse }.to_h
    end
  end
end
