include_recipe 'delivery-truck::default'

gem_package 'ruby-ntlm' do
  clear_sources true
  source node['coffee-truck']['gem-server'] if node['coffee-truck']['gem-server']
  action :nothing
end.run_action(:install)

if (java_changes?(changed_files))
  include_recipe 'java::default' if node['coffee-truck']['install-java']
  include_recipe 'maven::default' if node['coffee-truck']['install-maven']


  if (node['coffee-truck']['functional']['selenium'] && node['delivery']['change']['phase'] == 'functional')
    directory '/tmp/geckodriver' do
      action :create
      recursive true
    end

    remote_file 'gecko driver' do
      source node['coffee-truck']['functional']['gecko-driver']
      path '/tmp/geckodriver/geckodriver.tar.gz'
    end

    execute 'untar gecko' do
      action :run
      command 'tar -xvzf geckodriver.tar.gz'
      cwd '/tmp/geckodriver'
    end

    file "/usr/bin/geckodriver" do
      owner 'root'
      group 'root'
      mode 0755
      content lazy { ::File.open("/tmp/geckodriver/geckodriver").read }
      action :create
    end

    package 'firefox'
    package 'Xvfb'

    execute 'start_xvfb' do
      command 'Xvfb :10 -ac &'
    end
  end

end


