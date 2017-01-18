include_recipe 'delivery-truck::syntax'

java_changes?()

unless bumped_pom_version?()
  raise RuntimeError, "Artifact version unchanged - you have to increase the version in the pom file"
end 

unless ensure_snapshot?()
  raise RuntimeError, "-SNAPSHOT artifact required in your pom.xml file"
end