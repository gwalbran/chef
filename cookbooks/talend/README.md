Description
===========
Cookbook that provides resources to deploy and schedule talend jobs

Requirements
============
None

Attributes
==========
None

Usage
=====
Ensure there is an entry in the imos_artifacts data bag matching your artifact
name, then;

```talend_deploy "cpr-harvest" do
  action :deploy
  artifact_name "cpr-harvest-0-1"
end```

deploys cpr-harvest-0-1 artifact containing an autonomous talend job zip file
to /usr/local/talend/cpr-harvest

```talend_job "cpr_harvest" do
  action  :schedule
  hour    "18"
  weekday "5"
  minute  "00"
  context "Prod"
end```

schedule cpr_harvest to be run using the "Prod" context at 6pm on Fridays
