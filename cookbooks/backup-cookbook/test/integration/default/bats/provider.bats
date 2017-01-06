@test "provider creates file_test model" {
  test -f /home/backup/models/file_test.sh
  grep -q 'file_test /etc/passwd' /home/backup/models/file_test.sh
  grep -q 'file_test /etc/hosts'  /home/backup/models/file_test.sh
}

@test "provider creates database_test model" {
  test -f /home/backup/models/database_test.sh
  grep 'test_pgsql database_test.test_db_name test_host:test_port:test_db_name:test_username:test_password' \
    /home/backup/models/database_test.sh
}

@test "test simple backup" {
  sudo /home/backup/bin/backup.sh -m /home/backup/models/file_test.sh

  last_backup=`ls -1tr /home/backup/backup/file_test/ | tail -1`

  test -f /home/backup/backup/file_test/$last_backup/file_test/passwd
  diff /etc/passwd /home/backup/backup/file_test/$last_backup/file_test/passwd

  test -f /home/backup/backup/file_test/$last_backup/file_test/hosts
  diff /etc/hosts /home/backup/backup/file_test/$last_backup/file_test/hosts
}
