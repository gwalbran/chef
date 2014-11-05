@test "creates dir tree test1" {
  directory=/tmp/ftp_dir_tree/test1

  test -d $directory
  [ `stat --printf '%A' $directory` == "drwxr-xr-x" ]
  [ `stat --printf '%U' $directory` == "ftp" ]
  [ `stat --printf '%G' $directory` == "users" ]
}

@test "creates dir tree test2" {
  directory=/tmp/ftp_dir_tree/test1/test2

  test -d $directory
  [ `stat --printf '%A' $directory` == "drwxrwsr-x" ]
  [ `stat --printf '%U' $directory` == "ftp" ]
  [ `stat --printf '%G' $directory` == "users" ]
}
