# Plant SSH key
user_homedir=`getent passwd $SSH_USERNAME | cut -d: -f6`
test -d $user_homedir && mkdir -p $user_homedir/.ssh && \
    echo "$SSH_KEY" >> $user_homedir/.ssh/authorized_keys

exit
