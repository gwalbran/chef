#!/usr/bin/env ruby

require 'json'
require 'tempfile'
require 'trollop'
require 'open-uri'
require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}\n"
end

@config = nil
@noop = false

def prepare_file_list(objects)
  file_list = Tempfile.new('harvester_file_list')
  objects.each do |object|
    file_list.write(object + "\n")
  end
  file_list.close
  return file_list.path
end

def parse_file_path(file)
  real_file = file.split(",")[0]
  index_as = file.split(",")[1]

  real_file.start_with?("./") and real_file.sub!("./", "")

  if index_as.nil?
    if file =~ Regexp.new("^https?://")
      # Strip 'http://something/'
      index_as = real_file.gsub(Regexp.new("^https?://[^/]+/"), "")
      $logger.info "Stripping base URL for #{file}"
      $logger.info "File indexed as: #{index_as}"
    elsif @base
      index_as = File.join(@base, real_file)
      $logger.info "file: #{index_as}"
    end
  end

  if index_as.nil?
    $logger.error "Don't know how to index file '#{real_file}'"
    raise ArgumentError, "Don't know how to index file '#{real_file}'"
  end

  return real_file, index_as
end

def prepare_file(tmp_base, file, is_deletion = false)
  real_file, index_as = parse_file_path(file)
  real_file = File.absolute_path(real_file)

  if is_deletion
    $logger.info "DEL '#{real_file}' => '#{index_as}'"
  else
    $logger.info "ADD '#{real_file}' => '#{index_as}'"
    if ! @noop
      target_dir = File.join(tmp_base, File.dirname(index_as))
      target_file = File.join(tmp_base, index_as)

      begin
        FileUtils.mkdir_p(target_dir)
        FileUtils.ln_s(real_file, target_file)
      rescue Exception => e
        $logger.fatal e.message
        $logger.fatal "Error in symbolic linking '#{real_file}' => '#{target_file}'. Check to see if '#{target_file}' already exists'"
      end
    end
  end

  return index_as
end

def execute_for_files(name, exec, tmp_base, files_to_process)
  retval = 0
  Dir.mktmpdir { |tmp_log_dir|
    file_list = prepare_file_list(files_to_process)
    exec = exec % {
        :base => tmp_base,
        :file_list => file_list,
        :log_dir => tmp_log_dir
    }
    $logger.info "'#{name}': #{files_to_process}"
    $logger.info "Executing '#{exec}' for '#{files_to_process}'"

    if ! @noop
      `#{exec}`
      retval += $?.exitstatus

      stats_file = File.join(tmp_log_dir, "stats_file.txt")
      File.open(stats_file).each do |line|
        $logger.info line
      end
    end

    msg = "#{name}: #{files_to_process.count} file(s) "
    if 0 == retval
      $logger.info "#{msg} OK"
    else
      $logger.info "#{msg} FAILED"
    end

    File.unlink(file_list)
  }

  return retval
end

def match_and_execute(tmp_base, files)
  files_processed = []
  retval = 0

  # Enable bulk processing per harvester by traversing the list of harvesters
  # rather than the list of files. That way we can bunch together all the files
  # that one harvester need and potentially speed up things

  @config.each do |name, item|
    item["events"].each do |event|
      files_to_process = []

      event['regex'].each do |regex|
        files.each do |file|
          if file =~ Regexp.new(regex)
            files_to_process << file
          end
        end
      end

      exec = item['exec']

      if event['extra_params']
        exec += " #{event['extra_params']}"
      end

      retval += execute_for_files(name, exec, tmp_base, files_to_process.uniq) unless files_to_process.empty?

      files_processed += files_to_process
    end
  end

  files_not_processed = files.uniq - files_processed.uniq
  if ! files_not_processed.empty?
    $logger.info "Files not processed:"
    $logger.info "--------------------"
    $logger.info files_not_processed
    $logger.info "--------------------"
    retval += 1
  end

  return retval
end

def handle_files(files, delete = false, max_files)
  retval = 0

  $logger.info "Going to process a total of '#{files.size}' files"

  # Limit number of files in every iteration
  slice_size = [files.size(), max_files].min
  files.each_slice(slice_size).each do |files_slice|
    $logger.info "Processing slice with '#{files_slice.size}' files"
    files_to_index = []

    Dir.mktmpdir { |tmp_base|
      files_slice.each do |file|
        $logger.info "Preparing file '#{file}' in temp dir '#{tmp_base}'"
        files_to_index << prepare_file(tmp_base, file, delete)
      end
      retval = match_and_execute(tmp_base, files_to_index)
    }
  end

  return retval
end

if __FILE__ == $0
  # Arguments parsing
  opts = Trollop::options do
    banner <<-EOS
    Trigger harvesters for given files

    Example:
      Trigger harvester for file on disk:
          #{File.basename(__FILE__)} -c config.conf -f acorn.nc,IMOS/ACORN/2015/acorn.nc

      Trigger harvester for file via http:
          #{File.basename(__FILE__)} -c config.conf
            -f http://data.aodn.org.au/IMOS/opendap/ACORN/radial/FRE/2015/07/31/IMOS_ACORN_RV_20150731T000500Z_FRE_FV00_radial.nc

      Feed files from STDIN with base at `IMOS/ACORN/radial`:
          cd /mnt/opendap/1/IMOS/opendap/ACORN/radial && find . -type f | #{File.basename(__FILE__)} --stdin -c config.conf -b IMOS/ACORN/radial

      Delete an indexed file:
          #{File.basename(__FILE__)} -c config.conf
            -d IMOS/ACORN/radial/FRE/2015/07/31/IMOS_ACORN_RV_20150731T000500Z_FRE_FV00_radial.nc

    Example config file:
    {
        "trigger_name": {
            "exec": "/usr/bin/executable --base %{base} --file_list %{file_list} --log_dir %{log_dir}",
            "events": [{
                "regex": [
                    "^something\\.nc$",
                    "^somethin.*\\.nc$"
                ]
            }]
        }
    }

    Options:
EOS
    opt :config, "Config file",
      :type => :string,
      :short => '-c'
    opt :files, "Files to process (see example)",
      :type => :strings,
      :short => '-f'
    opt :base, "Base for all files, used for bulk loading",
      :type => :string,
      :short => '-b'
    opt :delete, "Delete mode (deletes files from index)",
      :short => '-d',
      :default => false
    opt :stdin, "Read files from STDIN",
      :short => '-s',
      :default => false
    opt :max, "Max files to process at a time",
      :short => '-m',
      :default => 2048
    opt :noop, "No-op, only shows what files will be indexed and how",
      :short => '-n',
      :default => false
  end

  Trollop::die :config, "Must specify config" if ! opts[:config]

  files = []
  if opts[:files]
    files = opts[:files]
  elsif opts[:stdin]
    Trollop::die :base, "Must specify base when using with --stdin" if ! opts[:base]
    files += STDIN.read.split("\n")
  else
    Trollop::die :files, "Must specify files" if ! opts[:files]
  end

  config_file = opts[:config]
  begin
    @config = JSON.parse(File.read(config_file))
  rescue
    Trollop::die :config, "Could not read config file '#{config_file}'"
  end

  @noop = opts[:noop]
  @base = opts[:base]

  exit(handle_files(files, opts[:delete], opts[:max]))
end
