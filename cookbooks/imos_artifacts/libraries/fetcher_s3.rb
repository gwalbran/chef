# require 'aws-sdk'

# Aws.config.update({
#   region: 'ap-southeast-2',
#   credentials: Aws::Credentials.new('AKIAJSQOUTB3IQFPN3TQ', 'U6ab+ybaIotKJsR7Nk+rjo2cDr7s6DPBFJqc74Xt')
# })

# s3 = Aws::S3::Client.new

# puts "before"
# resp = s3.get_object(bucket:'imos-artifacts', key:'jobs/geoserver_build/8/geoserver-1.0.0-imos.war')
# puts "after"

# puts resp.etag
