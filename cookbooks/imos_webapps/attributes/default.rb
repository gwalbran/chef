# Building of nokogiri fails without this, see:
# http://stackoverflow.com/questions/11380485/chef-why-are-resources-in-an-include-recipe-step-being-skipped
default['build_essential']['compiletime'] = true

default['imos_webapps']['log4j']['pattern'] = "%d %-5p [%-12t] [%X{username}] %c  - %m%n"
