include_recipe 'delivery-truck::syntax'

if (java_changes?(changed_files))

  unless bumped_pom_version?()
    raise RuntimeError, "Artifact version unchanged - you have to increase the version in the pom file"
  end

  unless ensure_snapshot?()
    raise RuntimeError, "-SNAPSHOT artifact required in your pom.xml file"
  end

  mvn 'pmd' do
    action :pmd
  end

  mvn 'checkstyle' do
    action :checkstyle
  end

end
