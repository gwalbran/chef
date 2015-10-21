require_relative 'spec_helper'

describe 'talend job helper' do
  before(:each) do
    allow(Chef::Log).to receive(:warn)
    allow(Chef::Log).to receive(:error)
  end

  tmp_file = nil
  new_entry_config = nil

  sample_config = '
{
    "harvester1": {
        "regex": [
            "^a/b/c/.*\\.nc$"
        ]
    },
    "harvester2": {
        "regex": [
            "^b/c/d/.*\\.nc$",
            "^c/d/e/.*\\.nc$"
        ]
    },
    "harvester3": {
        "regex": [
            "^b/c/d/.*\\.nc$",
            "^d/e/f/.*\\.nc$"
        ]
    }
}'

  describe 'triggers' do
    before :each do
      f = Tempfile.new("talend_triggers_test")
      f.write(sample_config)
      f.close
      tmp_file = f.path

      new_entry_config = {
        "exec" => "exec",
        "regex" => [ "regex1", "regex2"]
      }
    end

    after :each do
      FileUtils.rm_f(tmp_file)
    end

    it 'get_triggers' do
      expect(["harvester1", "harvester2", "harvester3"]).
        to eq(Talend::JobHelper.get_triggers(tmp_file))
    end

    def compare_entry(file, entry_name, config)
      current_config = Talend::JobHelper.json_as_hash_from_file(file)
      expect(current_config[entry_name]).to eq(config)
    end

    it 'add_trigger non existing file' do
      FileUtils.rm_f(tmp_file)
      Talend::JobHelper.add_trigger(tmp_file, "new_entry", new_entry_config['exec'], new_entry_config['regex'])

      expect(["new_entry"]).
        to eq(Talend::JobHelper.get_triggers(tmp_file))

      compare_entry(tmp_file, "new_entry", new_entry_config)
    end

    it 'add_trigger empty file' do
      File.truncate(tmp_file, 0)
      Talend::JobHelper.add_trigger(tmp_file, "new_entry", new_entry_config['exec'], new_entry_config['regex'])

      expect(["new_entry"]).
        to eq(Talend::JobHelper.get_triggers(tmp_file))

      compare_entry(tmp_file, "new_entry", new_entry_config)
    end

    it 'add_trigger existing file with valid json' do
      Talend::JobHelper.add_trigger(tmp_file, "new_entry", new_entry_config['exec'], new_entry_config['regex'])

      expect(["harvester1", "harvester2", "harvester3", "new_entry"]).
        to eq(Talend::JobHelper.get_triggers(tmp_file))

      compare_entry(tmp_file, "new_entry", new_entry_config)
    end

    it 'remove_trigger' do
      Talend::JobHelper.remove_trigger(tmp_file, "harvester2")
      expect(["harvester1", "harvester3"]).
        to eq(Talend::JobHelper.get_triggers(tmp_file))
    end
  end
end
