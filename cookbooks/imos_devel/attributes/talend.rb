# Target installation directory for talend
default['imos_devel']['talend']['install_dir'] = "/var/lib/talend"
# Chown talend installation to this user
default['imos_devel']['talend']['user'] = "root"

default['imos_devel']['talend']['packages'] = [
    {
        "source_url" => "https://s3-ap-southeast-2.amazonaws.com/imos-binary/static/talend/TOS_DI-r96646-V5.1.3.zip",
        "unzip_filter" => "TOS_DI-r96646-V5.1.3/*",
        "install_to" => "",
        "unzip" => true
    },
    {
        "source_url" => "https://s3-ap-southeast-2.amazonaws.com/imos-binary/static/talend/TOS-Spatial-5.4.1.zip",
        "unzip_filter" => "TOS-Spatial-5.4.1/plugins/*",
        "install_to" => "plugins",
        "unzip" => true
    },
    {
        "source_url" => "https://github.com/aodn/talend-codegen/releases/download/1.0.0/au.org.emii.talend.codegen_1.0.0.201308011725.jar",
        "install_to" => "plugins"
    },
    {
        "source_url" => "https://s3-ap-southeast-2.amazonaws.com/imos-binary/static/talend/stels_mdb_pack.zip",
        "unzip_filter" => "mdbdriver/*.jar",
        "install_to" => "lib/java",
        "unzip" => true
    }
]
