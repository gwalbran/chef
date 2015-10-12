require_relative 'spec_helper'

describe Chef::Recipe::CronjobSanitizer do
  before(:each) do
    allow(Chef::Log).to receive(:warn)
  end

  allowed_users = [ "test_user1", "test_user2" ]
  let(:cronjob_sanitizer) { Chef::Recipe::CronjobSanitizer.new(allowed_users) }

  describe 'get_user_for_cronjob' do
    it 'allows allowed users' do
      expect(cronjob_sanitizer.get_user_for_cronjob("test_user1")).to eq("test_user1")
      expect(cronjob_sanitizer.get_user_for_cronjob("test_user2")).to eq("test_user2")
      expect { cronjob_sanitizer.get_user_for_cronjob("test_user3") }.to raise_error
    end
  end

  describe 'sanitize_cronjob_line' do
    it 'allows MAILTO= lines' do
      expect(cronjob_sanitizer.sanitize_cronjob_line("MAILTO=test@example.com", "prefix")).to eq("MAILTO=test@example.com")
    end

    it 'mocks MAILTO= lines when asked to be mocked' do
      cronjob_sanitizer_mocked = Chef::Recipe::CronjobSanitizer.new([], true)
      expect(cronjob_sanitizer_mocked.sanitize_cronjob_line("MAILTO=test@example.com", "prefix")).to eq("# MOCKED OUT MAILTO=test@example.com")
    end

    it 'allows SHELL=/bin/bash line' do
      expect(cronjob_sanitizer.sanitize_cronjob_line("SHELL=/bin/bash", "prefix")).to eq("SHELL=/bin/bash")
      expect { cronjob_sanitizer.sanitize_cronjob_line("SHELL=/bin/csh", "prefix") }.to raise_error
    end

    it 'allows comments' do
      expect(cronjob_sanitizer.sanitize_cronjob_line("# this is a comment", "prefix")).to eq("# this is a comment")
      expect(cronjob_sanitizer.sanitize_cronjob_line("#this is a comment", "prefix")).to eq("#this is a comment")
      expect(cronjob_sanitizer.sanitize_cronjob_line(" # this is a comment", "prefix")).to eq("# this is a comment")
    end

    it 'denies commands from unauthorized users' do
      expect { cronjob_sanitizer.sanitize_cronjob_line("0 * * * * unauthorized_user some_command", "prefix") }.to raise_error
      expect { cronjob_sanitizer.sanitize_cronjob_line("0 * * * * unauthorized_user ls", "/bin") }.to raise_error
    end

    it 'denies commands that do not exist' do
      expect(cronjob_sanitizer.sanitize_cronjob_line("0 * * * * test_user1 some_command", "prefix")).to eq("")
    end

    it 'allows commands that exist from authorized users' do
      # assume /bin/ls exists :)
      expect(cronjob_sanitizer.sanitize_cronjob_line("0 * * * * test_user1 ls", "/bin")).to eq("0 * * * * test_user1 /bin/ls")
    end

    it 'handles bogus cron entries' do
      expect { cronjob_sanitizer.sanitize_cronjob_line("0 * * * unauthorized_user some_command", "prefix") }.to raise_error
      expect { cronjob_sanitizer.sanitize_cronjob_line("0 * * * * 0 unauthorized_user some_command", "prefix") }.to raise_error
      expect { cronjob_sanitizer.sanitize_cronjob_line("0 unauthorized_user some_command", "prefix") }.to raise_error
    end
  end

  describe 'sanitize_cronjob_file' do
    before(:each) do
      @unsanitized_cronjob = Tempfile.new('unsanitized_cronjob').path
      @sanitized_cronjob = Tempfile.new('sanitized_cronjob').path
    end

    after(:each) do
      FileUtils::rm_f([@unsanitized_cronjob, @sanitized_cronjob])
    end

    it 'handle typical file' do
      File.open(@unsanitized_cronjob, 'w') { |file|
        file.write("MAILTO=test@example.com\n")
        file.write("0 * * * * test_user1 ls\n")
      }

      cron_vars = {
        'TEMP_DIR_1' => "/tmp/1",
        'TEMP_DIR_2' => "/tmp/2"
      }

      cronjob_sanitizer.sanitize_cronjob_file(@unsanitized_cronjob, @sanitized_cronjob, "/bin", cron_vars)

      file = File.open(@sanitized_cronjob)
      contents = []
      file.each {|line|
        contents << line
      }

      expect(contents).to include("TEMP_DIR_1='/tmp/1'\n")
      expect(contents).to include("TEMP_DIR_2='/tmp/2'\n")

      expect(contents).to include("MAILTO=test@example.com\n")
      expect(contents).to include("0 * * * * test_user1 /bin/ls\n")
    end
  end
end
