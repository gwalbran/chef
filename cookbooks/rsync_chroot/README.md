rsync_chroot Cookbook
=====================
Chef Cookbook to configure rsync with ssh and chroot

Requirements
------------
### Platforms
- Debian, Ubuntu
- CentOS 6+, Red Hat 6+, Fedora, Amazon

Attributes
----------
 * `node['rsync_chroot']['rsync_options']` - default rsync options to use, `--server` is implied but this gives you control of some extra options
 * `node['rsync_chroot']['ssh_options']` - default ssh options to include in `authorized_keys`

LWRP
----
This cookbook provides a provider to install a SSH key for use with rsync for a given user.

For example, the following snippet will configure the given SSH key to be mapped to
`/data/staging` using user `staging`:

```rb
rsync_chroot_user 'rsync_staging_data' do
  user      "staging"
  key       "HERE_BE_SSH_PUBLIC_KEY"
  directory "/data/staging"
  comment   "user@org.com"
end
```

Usage
-----
#### rsync_chroot::default
Include `rsync_chroot` in your node's `run_list` or role's `run_list`:

```json
{
  "name":"my_name",
  "run_list": [
    "recipe[rsync_chroot]"
  ]
}
```

Use the LWRP in recipes as desired.

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors:: Dan Fruehauf

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
