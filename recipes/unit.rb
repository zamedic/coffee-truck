mvn 'unit' do
  action :unit
end

#Check Unit Tests
mvn 'jacoco' do
  action :jacoco_report
end

#Upload Snapshot
mvn 'upload' do
  action :upload
end
