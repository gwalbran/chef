name              "imos_vsftpd"
maintainer        "IMOS"
maintainer_email  "developers@emii.org.au"
license           "Apache 2.0"
description       "Installs and configures vsftpd for IMOS"
version           "1.0.0"

%w{ vsftpd imos_po }.each do |cb|
  depends cb
end
