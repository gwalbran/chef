# imos_mounts cookbook

A _very_ simple mount point enabling cookbook. Iterates over named mounts and checks for relevant entries in
the ```/etc/fstab``` file, if they are absent it appends them. If the provisioner is not chef solo it also
calls ```mount -a```

The nfs server is hardcoded into the recipe
until there is a need to make this more flexible I decided to keep it simple, please feel free to extend.

# Usage
recipe[imos_mounts]

# Attributes
Uses mount names under the aodn object

```
"aodn": {
    "mounts": ["imos-t3", "imos-t4"]
}
```

will result in mounts at /mnt/imos-t3 and /mnt/imos-t4 respectively

# Recipes
Just the default one

# Author

Author:: IMOS (<developers@emii.org.au>)
