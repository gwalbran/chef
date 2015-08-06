# Target installation directory for talend
default['imos_devel']['talend']['install_dir'] = "/var/lib/talend"
# Chown talend installation to this user
default['imos_devel']['talend']['user'] = "root"

default['imos_devel']['talend']['packages'] = [
    {
        "source_url" => "http://binary.aodn.org.au/static/talend/TOS_DI-r96646-V5.1.3.zip",
        "checksum" => "ca8dbff7cff1128aa22cde052f6c4c4099c9f8a05855fdf1bc7f385dfcf43549",
        "unzip_filter" => "TOS_DI-r96646-V5.1.3/*",
        "install_to" => "",
        "unzip" => true
    },
    {
        "source_url" => "http://binary.aodn.org.au/static/talend/TOS-Spatial-5.4.1.zip",
        "checksum" => "ce94b134bd464faf4a5743aa8fa84227000115f28427a87912e59b3dd2b721c8",
        "unzip_filter" => "TOS-Spatial-5.4.1/plugins/*",
        "install_to" => "plugins",
        "unzip" => true
    },
    {
        "source_url" => "https://github.com/aodn/talend-codegen/releases/download/1.0.0/au.org.emii.talend.codegen_1.0.0.201308011725.jar",
        "checksum" => "98368cfe5a4defdd4a02e45c887cb4d01a4f028f82a5be1774c970981c80e9e2",
        "install_to" => "plugins"
    },
    {
        "source_url" => "http://binary.aodn.org.au/static/talend/stels_mdb_pack.zip",
        "checksum" => "1ed59bddb320e6551fd9dbd150a8fda46910ba7274ab8a43f8c4c60fe8e45ec6",
        "unzip_filter" => "mdbdriver/*.jar",
        "install_to" => "lib/java",
        "unzip" => true
    }
]
