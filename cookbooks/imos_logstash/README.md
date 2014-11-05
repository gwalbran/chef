Description
===========

imos_logstash includes recipes for centralised logging and metrics, namely:

* server.rb - installs both the indexer and kibana components
* indexer.rb - receives events from logstash agents (clients) and stores them
* kibana.rb - the web interface for querying and visualising events (logs)
* agent.rb - configures a node to send events to the indexer

Requirements
============

Usage
=====

Apply the `logged` role to any nodes for which logs should be collected.
