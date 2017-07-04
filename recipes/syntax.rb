include_recipe 'delivery-truck::syntax'

if (java_changes?(changed_files))

  unless bumped_pom_version?()
    raise RuntimeError, "Artifact version unchanged - you have to increase the version in the pom file"
  end

  unless ensure_snapshot?()
    raise RuntimeError, "-SNAPSHOT artifact required in your pom.xml file"
  end

  mvn 'compile' do
    action :compile
  end

  mvn 'pmd' do
    only_if node['delivery']['config']['truck']['syntax']['execute_pmd']
    action :pmd
  end

  mvn 'checkstyle' do
    only_if node['delivery']['config']['truck']['syntax']['execute_checkstyle']
    action :checkstyle
  end

end
