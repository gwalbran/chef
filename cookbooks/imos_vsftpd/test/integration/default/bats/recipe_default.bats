@test "create vsftpd.conf" {
  test -f "/etc/vsftpd.conf"
}

@test "pasv address defined using public_ipv4 attribute" {
  grep -q "^pasv_address=test_public_ipv4" /etc/vsftpd.conf
}

@test "define users in vsftpd_pwdfile" {
  grep -q "^test_1:test_password_1" /etc/vsftpd_pwdfile
  grep -q "^test_2:test_password_2" /etc/vsftpd_pwdfile
}
