require_relative 'spec_helper'

describe 'talend trigger' do
  $logger = Logger.new("/dev/null")

  describe 'parse_file_path' do
    def verify_relative_path(inputs)
      inputs.each do |k, v|
        expect(parse_file_path(k)).to eq(v)
      end
    end

    it 'simple path name' do
      inputs = {
          "this/is/a/relative/path,index/as/this"   => ["this/is/a/relative/path", "index/as/this"],
          "./this/is/a/relative/path,index/as/this" => ["this/is/a/relative/path", "index/as/this"],
          "/this/is/an/absolute/path,index/as/this" => ["/this/is/an/absolute/path", "index/as/this"]
      }
      verify_relative_path(inputs)
    end

    it 'http(s) path names' do
      inputs = {
          "http://something.com/abc/indexed_file"  => ["http://something.com/abc/indexed_file", "abc/indexed_file"],
          "https://something.com/abc/indexed_file" => ["https://something.com/abc/indexed_file", "abc/indexed_file"]
      }
      verify_relative_path(inputs)
    end

    it 'with base path' do
      @base = "/base_dir"
      inputs = { "relative/path/file" => ["relative/path/file", "/base_dir/relative/path/file"] }
      verify_relative_path(inputs)
    end

    it 'no base path' do
      expect { parse_file_path("relative/path/file") }.to raise_error(ArgumentError)
    end
  end


  describe 'match_and_execute' do
    before :each do
      @files_processed = {}
      @executed_commands = []

      def execute_for_files(name, exec, tmp_base, files_to_process)
        @files_processed[name] = files_to_process
        @executed_commands << exec
        return 0
      end

      json = '
{
    "harvester1": {
        "exec": "command_1",
        "events": [{
            "regex": [
                "^a/b/c/.*\\.nc$"
            ]
        }]
    },
    "harvester2": {
        "exec": "command_2",
        "events": [{
            "regex": [
                "^b/c/d/.*\\.nc$",
                "^c/d/e/.*\\.nc$"
            ],
            "extra_params": "arg1 arg2"
        }]
    },
    "harvester3": {
        "exec": "command_3",
        "events": [{
            "regex": [
                "^b/c/d/.*\\.nc$",
                "^d/e/f/.*\\.nc$"
            ]
        }]
    },
    "harvester4": {
        "exec": "command_4",
        "events": [{
            "regex": [
                "^e/f/g/.*\\.nc$"
            ],
            "extra_params": "arg3"
        },{
            "regex": [
                "^f/g/h/.*\\.nc$"
            ],
            "extra_params": "arg4"
        }]
    }
}'
      @config = JSON.parse(json)
    end

    it 'single file, single harvester' do
      files = ["a/b/c/something.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq("harvester1" => files)
      expect(@executed_commands).to eq(['command_1'])
    end

    it 'single file, multi harvester' do
      files = ["b/c/d/something.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq({"harvester2" => files, "harvester3" => files})
      expect(@executed_commands).to eq(['command_2 arg1 arg2', 'command_3'])
    end

    it 'multi file, single harvester' do
      files = ["a/b/c/something.nc", "a/b/c/something2.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq({"harvester1" => files})
      expect(@executed_commands).to eq(['command_1'])
    end

    it 'multi file, multi harvester' do
      files = ["a/b/c/something.nc", "a/b/c/something2.nc", "b/c/d/something.nc", "d/e/f/something.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq({
        "harvester1" => [files[0], files[1]],
        "harvester2" => [files[2]],
        "harvester3" => [files[2], files[3]]
      })
      expect(@executed_commands).to eq(['command_1', 'command_2 arg1 arg2', 'command_3'])
    end

    it 'single file, no harvester executed' do
      files = ["unmatched"]
      expect(match_and_execute("", files)).to be > 0
    end

    it 'multi file, no harvester executed' do
      files = ["b/c/d/something.nc", "unmatched"]
      expect(match_and_execute("", files)).to be > 0
    end

    it 'multi event, single harvester selected' do
      files = ["f/g/h/something.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq({"harvester4" => files})
      expect(@executed_commands).to eq(['command_4 arg4'])
    end

    it 'multi event, multiple harvesters selected' do
      files = ["f/g/h/something.nc", "e/f/g/something.nc"]
      match_and_execute("", files)
      expect(@files_processed).to eq({"harvester4" => [files[1]], "harvester4" => [files[0]]})
      expect(@executed_commands).to eq(['command_4 arg3', 'command_4 arg4'])
    end
  end
end
