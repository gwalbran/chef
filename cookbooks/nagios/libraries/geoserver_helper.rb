
include Chef::Mixin::ShellOut

module Nagios
  class GeoServerHelper
    def initialize()
    end

    # simply clones a git repository into `dir`
    def clone_git_repo(dir, git_repo, git_branch)
      if ! shell_out!("git clone #{git_repo} --branch #{git_branch} --depth 1 #{dir}")
        Chef::Application.fatal!("Could not clone repository '#{git_repo}', branch '#{git_branch}'")
      end
    end

    def decode_geoserver_layers(dir)
      # decode a geoserver config directory into an array of layers
      # returns [{:prefix=>string, :name=>string, :enabled=>bool}]

      # includes
      require 'find'
      require 'fileutils'
      require 'nokogiri'

      # mappings between objects
      layers = {}
      features = {}
      coverages = {}
      namespaces = {}

      # process files in path
      Find.find(dir) do |path|

        # skip directories
        next unless FileTest.file?(path)
        # skip any path that doesn't have a .xml extension
        next unless File.extname(path) == '.xml'

        # decode xml
        xml = Nokogiri::XML(File.open(path))

        # extract geoserver objects
        # layers
        layer_id = xml.at_xpath("/layer/id")
        if layer_id
          name = xml.at_xpath("/layer/name")
          Chef::Application.fatal!("layer missing id") unless name
          feature_id = xml.at_xpath("/layer/resource/id")
          Chef::Application.fatal!("layer missing feature id") unless feature_id
          enabled_raw = xml.at_xpath("/layer/enabled")
          enabled = true
          if enabled_raw && enabled_raw.inner_html == "false"
            enabled = false
          end
          layers[layer_id.inner_html] = { name: name.inner_html, feature_id: feature_id.inner_html, enabled: enabled }
        end

        # feature types
        feature_id = xml.at_xpath("/featureType/id")
        if feature_id
          name = xml.at_xpath("/featureType/name")
          Chef::Application.fatal!("feature missing name") unless name
          namespace_id = xml.at_xpath("/featureType/namespace/id")
          Chef::Application.fatal!("feature missing namespace") unless namespace_id
          features[feature_id.inner_html] = { name: name.inner_html, namespace_id: namespace_id.inner_html }
        end

        # coverages
        coverage_id = xml.at_xpath("/coverage/id")
        if coverage_id
          name = xml.at_xpath("/coverage/name")
          Chef::Application.fatal!("coverage missing name") unless name
          namespace_id = xml.at_xpath("/coverage/namespace/id")
          Chef::Application.fatal!("coverage missing namespace") unless namespace_id
          coverages[coverage_id.inner_html] = { name: name.inner_html, namespace_id: namespace_id.inner_html }
        end

        # namespaces
        namespace_id = xml.at_xpath("/namespace/id")
        if namespace_id
          prefix = xml.at_xpath("/namespace/prefix")
          Chef::Application.fatal!("namespace missing prefix") unless prefix
          namespaces[namespace_id.inner_html] = { prefix: prefix.inner_html }
        end
      end

      # denormalize layers
      result = []
      layers.each() do |layer_id,layer|

        if features[layer[:feature_id]]
          feature = features[layer[:feature_id]]
          namespace = namespaces[feature[:namespace_id]]
          Chef::Application.fatal!("no namespace #{feature[:namespace_id]} for feature #{layer[:name]}") unless namespace
          result << { prefix: namespace[:prefix], name: layer[:name], enabled: layer[:enabled] }

        elsif coverages[layer[:feature_id]]
          coverage = coverages[layer[:feature_id]]
          namespace = namespaces[coverage[:namespace_id]]
          Chef::Application.fatal!("no namespace #{coverage [:namespace_id]} for coverage #{layer[:name]}") unless namespace
          result << { prefix: namespace[:prefix], name: layer[:name], enabled: layer[:enabled] }

        else
          Chef::Application.fatal!("no feature or coverage '#{layer[:feature_id]}' for layer '#{layer[:name]}'")

        end
      end
      result
    end

    # returns an array of geoserver layers for a given webapp block
    def get_layers_for_application(application)

      if ! application['data_bag']
        Chef::Log.warn("Node '#{n['fqdn']}' has a geoserver instance with no data bag defined!")
        return []
      end

      geoserver_data_bag = Chef::DataBagItem.load("geoserver", application['data_bag']).to_hash

      git_repo = nil
      git_branch = nil

      # operate on git repo if and only if layer_probing is not disabled
      if geoserver_data_bag['layer_probing'] != false
        # parse layers from git repo
        git_repo = geoserver_data_bag['git_repo']
        git_branch = geoserver_data_bag['git_branch']
      end


      Chef::Log.info("Monitoring #{application['data_bag']}, git repo '#{git_repo}'")

      return get_layers_for_git_repo(
        geoserver_data_bag['layers'],
        geoserver_data_bag['layer_filters'],
        git_repo, git_branch
      )
    end

    # return true if layer_name matches any regex filter
    def match_filters(layer_filters, layer_name)
      # empty filter? monitor all layers
      nil == layer_filters and return true

      include_patterns = []
      layer_filters['include'] and include_patterns = layer_filters['include']

      exclude_patterns = []
      layer_filters['exclude'] and exclude_patterns = layer_filters['exclude']

      # by default, if there are layer filters, black list everything, that is
      # don't monitor anything by default
      retval = false

      # whitelist first
      include_patterns.each do |pattern|
        if (layer_name =~ /#{pattern}/) != nil
          retval = true
        end
      end

      # then blacklist
      exclude_patterns.each do |pattern|
        if (layer_name =~ /#{pattern}/) != nil
          retval = false
        end
      end

      return retval
    end

    # assemble an array of monitored layers
    # probe git geoserver config repository for layers and merge with the layers
    # provided in the data bag, giving priority to layers in the data bag
    def get_layers_for_git_repo(data_bag_layers, layer_filters, git_repo, git_branch)

      # if the git repository is unspecified, return the original
      # items in the data bag
      if ! git_repo
        return data_bag_layers
      end

      # clone and extract layers
      tmp_dir = Dir.mktmpdir
      clone_git_repo(tmp_dir, git_repo, git_branch)
      layers = decode_geoserver_layers(tmp_dir)
      FileUtils.rm_rf(tmp_dir)

      # translate to expected template structure
      retval = []
      layers.each() do |layer|
        next if not layer[:enabled]
        next if not match_filters(layer_filters, layer[:name])
        # layer is wms, unless it has a '_data' or '_url' suffix, then it's wfs
        type = "wms"
        if layer[:name][-5,5] == "_data" || layer[:name][-4,4] == "_url"
            type = "wfs"
        end
        retval << ({
            'type'      => type,
            'workspace' => layer[:prefix],
            'name'      => layer[:name]
        })
      end

      # here comes the difficult part, search if there's anything in the data
      # bag that should override the layer's configuration and override the
      # relevant values
      # search if the layer already exists in the data bag
      data_bag_layers.each do |layer_overrides|
        retval.select { |item|
          item['type'] == layer_overrides['type'] &&
          item['workspace'] == layer_overrides['workspace'] &&
          item['name'] == layer_overrides['name'] }
            .each do |matching_layer|

            Chef::Log.info("Overriding layer '#{layer_overrides['name']}' with '#{layer_overrides}'")
            matching_layer.merge!(layer_overrides)
        end
      end if data_bag_layers

      return retval
    end
  end
end
