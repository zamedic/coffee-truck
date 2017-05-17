coffee-truck Cookbook
===================
Coffee Truck enables Chef Automate to Delivery Java Projects using the Maven Build Engine

The truck performs the following operations

### Default
As the default phase runs before each of the phases and runs as root, we install the following 
packages required by the coffee-truck
- Java
- Maven

The following packages are also installed if the Selenium Attribute is enabled
- Gecko Driver
- Firefox
- Xvfb

### Syntax
The following checks are performed
- Has the pom.xml version been bumped
- Is the artifact a -SNAPSHOT
#### Does the code compile

```
mvn compile package install -Dmaven.test.skip=true
```
#### Run PMD scans

By default it runs

```
mvn pmd:pmd -Daggregate=true -Dformat=xml
```
When the attribute ['delivery']['config']['truck']['single_level_project'] is set to true, 
coffee-truck runs

```
mvn pmd:pmd -Daggregate=false -Dformat=xml
```

the PMD rules can be configured via the pom.xml file

````xml
<project>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-pmd-plugin</artifactId>
        <version>3.7</version>
        <configuration>
          <rulesets>
            <ruleset>/rulesets/java/basic.xml</ruleset>
            <ruleset>/rulesets/java/braces.xml</ruleset>
            <ruleset>/rulesets/java/naming.xml</ruleset>
            <ruleset>/rulesets/java/codesize.xml</ruleset>
            <ruleset>/rulesets/java/comments.xml</ruleset>
            <ruleset>/rulesets/java/design.xml</ruleset>
            <ruleset>/rulesets/java/empty.xml</ruleset>
            <ruleset>/rulesets/java/finalizers.xml</ruleset>
            <ruleset>/rulesets/java/imports.xml</ruleset>
            <ruleset>/rulesets/java/j2ee.xml</ruleset>
            <ruleset>/rulesets/java/javabeans.xml</ruleset>
            <ruleset>/rulesets/java/junit.xml</ruleset>
            <ruleset>/rulesets/java/logging-java.xml</ruleset>
            <ruleset>/rulesets/java/migrating_to_15.xml</ruleset>
            <ruleset>/rulesets/java/naming.xml</ruleset>
            <ruleset>/rulesets/java/optimizations.xml</ruleset>
            <ruleset>/rulesets/java/strings.xml</ruleset>
            <ruleset>/rulesets/java/typeresolution.xml</ruleset>
            <ruleset>/rulesets/java/unnecessary.xml</ruleset>
            <ruleset>/rulesets/java/unusedcode.xml</ruleset>
          </rulesets>
        </configuration>
      </plugin>     
    </plugins>
  </build>
</project>
````
If coffee trucks detects an increase in the amount of total PMD Violations, coffee-truck fails the build.
 
Once code is accepted via Chef Automate, a data bag with the name of 'delivery' is updated with the new value of the PMD violations. 

#### Run Checkstyle checks
By default, the following command is executed

````
mvn checkstyle:checkstyle-aggregate
````
unless the attribute ['delivery']['config']['truck']['single_level_project'] is set to true, in 
which case the following is executed

````
mvn checkstyle:checkstyle
````

Checkstyle can be configured via the pom.xml file

````xml
<project>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-checkstyle-plugin</artifactId>
        <version>2.17</version>
        <configuration>
          <configLocation>google_checks.xml</configLocation>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
````
If coffee-truck detects an increase in the total amount of Checkstyle violations, it will fail the 
build.
 
Once code is accepted via Chef Automate, a data bag with the name of 'delivery' is updated with the new value of the PMD violations. 

### Unit
#### Unit Tests
By default, the following command is executed

````
mvn surefire-report:report-only -Daggregate=true
````
Unless the ['delivery']['config']['truck']['single_level_project'] attribute is set to true, in which 
case the following is executed

```
mvn surefire-report:report-only
```

Surefire can be configured via the pom.xml file

```xml
<project>
  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.19.1</version>
        <configuration>
          <skipTests>${skip.unit.tests}</skipTests>
          <parallel>all</parallel>
          <perCoreThreadCount>true</perCoreThreadCount>
          <threadCount>2</threadCount>
          <forkCount>2C</forkCount>
          <reuseForks>true</reuseForks>
          <additionalClasspathElements>
            <additionalClasspathElement>src/main/webapp/</additionalClasspathElement>
          </additionalClasspathElements>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```
#### Jacoco Coverage
Jacoco is used to measure the unit test coverage of the build
 
 the following command is executed

```
mvn org.jacoco:jacoco-maven-plugin:report
```

If coffee-truck detects a drop in the overall coverage of the build, it will fail the build. 

Once code is accepted via Chef Automate, a data bag with the name of 'delivery' is updated with the new value of the PMD violations. 

#### Upload Artifact
The SNAPSHOT artifact is uploaded to your Distribution Management as defined in your pom.xml.

The following command is executed

```
mvn deploy -Pno-tests
```
### Lint
#### Compile
The code is compiled in this phase as Find Bugs scans compiled code. 
#### Findbugs
The following command is executed

```
mvn findbugs:findbugs
```
Findbugs can be configured via your pom.xml file

````xml
<project>
  <build>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>findbugs-maven-plugin</artifactId>
        <version>3.0.4</version>
        <configuration>
          <xmlOutput>true</xmlOutput>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
````

If the coffee-truck detects an increase in the number of findbugs violations, the build is failed.  

Once code is accepted via Chef Automate, a data bag with the name of 'delivery' is updated with the new value of the PMD violations. 

###Functional
The following command is executed

```commandline
mvn failsafe:verify -Pintegration-tests -f #{node['delivery']['workspace']['repo']}/pom.xml -Dwebdriver.gecko.driver=/usr/bin/geckodriver -q
```

###Provision
No special operations happen in the provision phase

###Publish
This phase performs a Maven release, first, the following command is executed

First, the code sets up git

```commandline
git config user.email '#{node['coffee-truck']['release']['email']}'
git config user.name '#{node['coffee-truck']['release']['user']}'
git pull
```

Then it prepares the release

```commandline
mvn -B release:prepare -Darguments='-Dmaven.test.skip=true' -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true
```

Coffee-truck checks if the prepare was successful

```commandline
mvn surefire-report:report-only -Daggregate=true
```

The release is then performed 

```commandline
mvn -B release:perform  -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true
```

If everything ran succesfully, the released version number is then used to define the new project 
version for deployment. The version number is available as a node attribute node['applications']['application name']
where application name is derived from ['delivery']['change']['project']

###Quality
No special operations are performed during this phase by the coffee-truck
###Security
If a checkmarx url has been defined via ['delivery']['config']['truck']['security_url'] the stats will
be retreived and made available for you to use as required. 
###Smoke
No Special operations are performed during this phase by the coffee-truck

Requirements
------------
#### packages
- `delivery-truck` - Base delivery truck is invoked before the coffee-truck phases are invoked
- `java` - Installs the Java environment
- `maven` - Installs maven

Attributes
----------
#### coffee-truck::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['install-maven']</tt></td>
    <td>Boolean</td>
    <td>Should the maven default recipe be invoked</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['install-java']</tt></td>
    <td>Boolean</td>
    <td>Should the java default recipe be invoked</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['functional']['selenium']</tt></td>
    <td>Boolean</td>
    <td>Should the Selenium be configured and executed as part of the functional phase</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['functional']['gecko-driver']</tt></td>
    <td>String</td>
    <td>URL of the gecko driver</td>
    <td><tt>https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-linux64.tar.gz</tt>
    </td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['security']['checkmarx']['address']</tt></td>
    <td>String</td>
    <td>Checkmarx URL</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['security']['checkmarx']['port']</tt></td>
    <td>Numeric</td>
    <td>Checkmarx URL Port</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['security']['checkmarx']['key']</tt></td>
    <td>String</td>
    <td>Checkmarx Key</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['maven']['settings']</tt></td>
    <td>String</td>
    <td>Additional maven settings passed during the maven executions as part of the -s parameter</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['maven']['settings']</tt></td>
    <td>String</td>
    <td>Additional maven settings passed during the maven executions as part of the -s parameter</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['release']['user']</tt></td>
    <td>String</td>
    <td>Git user</td>
    <td><tt>blank</tt></td>
  </tr>
  <tr>
    <td><tt>['coffee-truck']['release']['email']</tt></td>
    <td>String</td>
    <td>Git user Email</td>
    <td><tt>blank</tt></td>
  </tr>
</table>

Usage
-----
#### coffee-truck::default
Once your project is added to delivery, you should have a .delivery folder within your project.

 If your project is a single level project, so it doesnt contain multiple pom.xml files, update the 
 config.json file to set the attribute as

```json
 {
   "version": "2",
   "job_dispatch": {
     "version": "v2"
   },
   "build_cookbook": {
     "name": "build_cookbook",
     "path": ".delivery/build_cookbook"
   },
   "truck": {
     "single_level_project": "true"
   },
   "skip_phases": [],
   "build_nodes": {},
   "dependencies": []
 }
```

within each of the recipes inside the .delivery/recipes/ update the recipes to call the coffee truck

for example, deploy.rb

```commandline
include_recipe 'coffee-truck::deploy'
```

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
