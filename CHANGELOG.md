sbis-truck CHANGELOG
====================

This file is used to list changes made in each version of the sbis-truck cookbookName.

1.7.0
-----
- Added Codacy support. 

1.6.0
-----
- Added ability to bump versions of dependencies in pom.xml 

1.5.0
-----
- Adding ability to disable functional tests with ['delivery']['config']['truck']['skip_functional_tests']['delivery']['config']['truck']['skip_functional_tests'] attribute

1.4.0
-----
- Checking if maven released successfully by tailing the end of the log file and checking for 
"BUILD SUCCESS" since mvn doesnt appear to be returning a response code of non 0 when the build fails

1.3.4
-----
- Fixing mvn path
- Settting default jdk version to 8

1.3.3
------
- Marc Arndt - Setting chefNode['maven']['setup_bin'] to true

1.3.2
-----
- Marc Arndt - Initial release of coffee-truck



- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.

