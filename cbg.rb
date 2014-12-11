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

# get folder information
r = g.call(:CabinetGetFolderInfo)
#p r	# raw response
folders = r.doc.xpath('//folder')
puts 'Folder information'
folders.each do |f|
	printf "% 5s % 5s %-14s %s\n", f.attr('id'), f.attr('code'),
	    f.xpath('title').inner_text,
	    f.xpath('creator_display_name').inner_text
end
puts ''

# get file information
hid = '1'
r = g.call(:CabinetGetFileInfo, { '@hid' => hid })
files = r.doc.xpath('//files')
puts "Information of file ID ``#{hid}'':"
files.each do |f|
	printf "% 5s % 5s %s\n", hid, f.attr('parent_id'), f.attr('parent_code')
end
puts ''

# get application status
r = g.call(:BaseGetApplicationStatus)
puts 'Application status:'
r.doc.xpath('//application').each do |a|
	printf "% 12s %s\n", a.attr('code'), a.attr('status')
end
puts ''

# get workflow (this needs administrative privilege)
rfid = '1'
params = { 'manage_request_parmeter' => { '@request_form_id' => rfid } }
r = g.call(:WorkflowGetRequests, params)
items = r.doc.xpath('//manage_item_detail')
puts "Request for form ``#{rfid}'' in workflow:"
items.each do |i|
	printf "% 5d %s\n", i.attr('pid'), i.attr('status')
end
