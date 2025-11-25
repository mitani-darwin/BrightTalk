# Raise Rack multipart part limit to avoid "Maximum file multiparts in content reached" errors
Rack::Utils.multipart_part_limit = ENV.fetch("RACK_MULTIPART_LIMIT", 1024).to_i
