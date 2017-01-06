include_recipe "backup::default"

backup 'file_test' do
  params ({
    :files => [ "/etc/passwd", "/etc/hosts" ]
  })
end

databases = []
databases.push({
  'type'     => 'test_pgsql',
  'host'     => 'test_host',
  'port'     => 'test_port',
  'name'     => 'test_db_name',
  'username' => 'test_username',
  'password' => 'test_password'
})

backup 'database_test' do
  params ({
    :databases => databases
  })
end
