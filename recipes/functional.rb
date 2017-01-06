include_recipe 'delivery-truck::functional'


unless node['delivery']['change']['stage'] == 'delivered'


  directory '/tmp/geckodriver' do
    action :create
    recursive true
  end

  remote_file 'gecko driver' do
    source 'http://plinrepo1v.standardbank.co.za/repo/software/selenium/geckodriver-v0.12.0-linux64.tar.gz'
    path '/tmp/geckodriver/geckodriver.tar.gz'
  end

  execute 'untar gecko' do
    action :run
    command 'tar -xvzf geckodriver.tar.gz'
    cwd '/tmp/geckodriver'
  end

  execute 'start_xvfb' do
    command 'Xvfb :10 -ac &'
  end

  mvn 'functional' do
    action :functional
  end
end
