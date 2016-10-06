mvn 'unit' do
  action :unit
end


mvn 'sonar' do
  action :sonar
  definitions('sonar.host.url' => node['delivery']['config']['sonar']['host'])
end

#Upload Snapshot
mvn 'upload' do
  action :upload
end
