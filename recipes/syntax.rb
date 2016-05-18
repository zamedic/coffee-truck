include_recipe 'delivery-test::syntax'


unless bumped_pom_version?(node['delivery']['workspace']['repo'])
  raise RuntimeError, "Artifact version unchanged - you have to increase the version in the pom file"
end 
