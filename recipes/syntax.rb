include_recipe 'delivery-truck::syntax'


unless bumped_pom_version?(node['delivery']['workspace']['repo'])
  raise RuntimeError, "Artifact version unchanged - you have to increase the version in the pom file"
end 

unless ensure_shapshot?(node['delivery']['workspace']['repo'])
  raise RuntimeError, "-SNAPSHOT artifact required in your pom.xml file"
end