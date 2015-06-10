# Target installation directory for talend
default['imos_devel']['talend']['install_dir'] = "/var/lib/talend"
# Chown talend installation to this user
default['imos_devel']['talend']['user'] = "root"

default['imos_devel']['talend']['source_url']              = "http://binary.aodn.org.au/static/talend/TOS_DI-r96646-V5.1.3.zip"
default['imos_devel']['talend']['source_checksum']         = "ca8dbff7cff1128aa22cde052f6c4c4099c9f8a05855fdf1bc7f385dfcf43549"
default['imos_devel']['talend']['sdi_source_url']          = "http://binary.aodn.org.au/static/talend/TOS-Spatial-5.1.1.zip"
default['imos_devel']['talend']['sdi_source_checksum']     = "fc674d2d44e20fb3fc88c25117952ef8044d53e1c17dbd36c7c257dce050ba15"
default['imos_devel']['talend']['codegen_source_url']      = "https://github.com/aodn/talend-codegen/releases/download/1.0.0/au.org.emii.talend.codegen_1.0.0.201308011725.jar"
default['imos_devel']['talend']['codegen_source_checksum'] = "98368cfe5a4defdd4a02e45c887cb4d01a4f028f82a5be1774c970981c80e9e2"
