include_recipe 'delivery-truck::lint'

if (java_changes(changed_files))
  mvn 'compile' do
    action :compile
  end

  mvn 'checkstyle' do
    action :checkstyle
  end

  mvn 'pmd' do
    action :pmd
  end
end