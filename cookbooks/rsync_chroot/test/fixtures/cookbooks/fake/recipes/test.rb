include_recipe "rsync_chroot::default"

rsync_chroot_user 'test_user_1' do
  user      "root"
  key       "SSH_KEY_1"
  directory "DIRECTORY_1"
  comment   "COMMENT_1"
end

rsync_chroot_user 'test_user_2' do
  user      "root"
  key       "SSH_KEY_2"
  directory "DIRECTORY_2"
  comment   "COMMENT_2"
end
