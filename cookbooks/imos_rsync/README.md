Description
===========

Wrapper cookbook for dealing with rsync. Supports 2 ways of configuring rsync:
 * Unencrypted rsync (port 873)
 * chrooted rsync via SSH (recommended)

Requirements
============

Depends on:
 * rsync
 * rsync_chroot


Usage
=====

Rsync + chroot
==============
In your node definition you can add:
```
    "imos_rsync": {
        "chroot_users": [
            "acorn"
        ]
    }
```

Then create `data_bags/rsync_chroot_users/acorn.json` with:
```
{
    "id": "acorn",
    "directory": "/acorn/staging",
    "ssh_key": "ssh-rsa YOUR_SSH_RSA_KEY",
    "email": "someone@acorn.org.au"
}
```
