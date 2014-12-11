#!/usr/pkg/bin/ruby193

require './garoonapi'

if ARGV.length != 3 then
	progname = File.basename($0)
	puts "Usage: #{progname} <base URI> <username> <password>"
	exit
end
uribase = ARGV[0]
username = ARGV[1]
password = ARGV[2]

#
g = GaroonAPI.new(uribase, username, password)

# get file information
params = { '@hid' => 1 }
r = g.call(:CabinetGetFileInfo, { '@hid' => 1 })
p r	# raw response
p r.doc	# Nokogiri style
# do something...

# get application status
r = g.call(:BaseGetApplicationStatus)
p r	# raw response
p r.doc	# Nokogiri style
# do something...
