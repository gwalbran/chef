@test "provider created authorized_keys entry" {
  tmp_content=`mktemp`
  echo 'command="rsync -a --server . DIRECTORY_1",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding SSH_KEY_1 COMMENT_1' >> $tmp_content
  echo 'command="rsync -a --server . DIRECTORY_2",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding SSH_KEY_2 COMMENT_2' >> $tmp_content
  diff /root/.ssh/authorized_keys $tmp_content
}
