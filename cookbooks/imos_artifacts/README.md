Description
===========
Cookbook that provides functionality to unzip and deploy an imos artifact to a target directory

Requirements
============
None

Attributes
==========
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:imos_artifacts][:ci_url]</tt></td>
    <td>String</td>
    <td>Continuous Integration URL (Jenkins)</td>
    <td><tt>https://ci.aodn.org.au</tt></td>
  </tr>
</table>

Usage
=====

Consider you have a data bag under `imos_artifacts/some_artifact.rb` which looks like:
```
{
  "id": "some_artifact_from_jenkins",
  "job": "here_be_jenkins_job_name",
  "filename": "here_be_file_to_take_from_job_and_use_as_artifact.war"
}
```

You can also download files from a given URL:
```
{
  "id": "some_artifact_from_the_web",
  "url": "http://repo.emii.org.au/archiva/repository/internal/artifact.war",
  "type": "http",
  "username": "http_user",
  "password": "http_password"
}
```

Now the provider can be used with:
```
imos_artifacts_deploy 'some_artifact_from_jenkins' do
  artifact_id 'some_artifact'
  install_dir '/usr/local/java/artifacts'
end
```

This will deploy the artifact `some_artifact` into `/usr/local/java/artifacts/some_artifact`.

