# hipaa request
		# TODO - don't use this one.  ndc_selen.py actually works.

import csv
import pickle
import requests  # for python3 requires pip3 install requests the first time
import urllib
from lxml import etree
import numpy as np
import time
import json  # https://www.w3schools.com/python/python_json.asp


# read codes:
codes = []
with open('/Users/austinbean/Desktop/programs/opioids/unique_ndcs.csv') as f:
    rdr = csv.reader(f, delimiter = ',')
    for row in rdr: 
        codes.append(row)

# this is necessary
url_start = 'http: // www.hipaaspace.com/api/ndc/getcode?'
    # seems like this actually needs the dashes.  WTF
# q=00023218105&rt=json&token=90B0031BCED14BCD880C273DA32F744D504F2C45687A41AF9B9629FB790718A7'

# http://www.hipaaspace.com/api/ndc/getcode?q=00023218105&rt=json&token=90B0031BCED14BCD880C273DA32F744D504F2C45687A41AF9B9629FB790718A7
urls = []
curr_add = " "

# To reset and start again:
for i in range(0, len(hospdata)):
	if hospdata[i][len(hospdata[i])-1] == 'FOUND':
		hospdata[i][len(hospdata[i])-1] = ''


# this actually requests the data via GMaps.

# Keep track of the columns where certain pieces of data are recorded:
addr_add = 8
city_add = 4
intensive_add = 6
soloint_add = 13
lat_add = 14
lon_add = 15
fid_add = 0

# Different address locations for the supplementary_addresses file.
addr_add = 4
city_add = 3
fid_add = 0
lat_add = 7
lon_add = 8


for i in range(0, len(hospdata)):
	# reset these strings to be empty to avoid looking up in the wrong city.
	street = ''
	town = ''
	lat = ''
	lon = ''
	url_req = ''
	if hospdata[i][len(hospdata[i])-1] != 'FOUND':
		if not ((hospdata[i][addr_add] == '')):  # search if the address is not missing?
			if curr_add == hospdata[i][addr_add]:  # curr_add starts as the empty string
				print(hospdata[i][addr_add])
				hospdata[i].append(lat)
				hospdata[i].append(lon)
				hospdata[i].append('FOUND')
				print("doing nothing")
			elif curr_add != hospdata[i][addr_add]:
				# can also get city, county, from these requests if missing.
				street = 'address='+urllib.parse.quote_plus(hospdata[i][addr_add])+','
				town = '+'+urllib.parse.quote_plus(hospdata[i][city_add])+','
				state = '+TX'
				url_req = url_start+street+town+state + \
					'&key=AIzaSyB97zCPvHJQyOzNtFwQVfn3u2JtT-KbIdE'
				urls.append(url_req)
				a = requests.get(url_req)
				page_xml = etree.XML(a.content)
				lat_set = page_xml.xpath('//location/lat')
				lon_set = page_xml.xpath('//location/lng')
				if (len(lat_set) > 0) and (len(lon_set) > 0):
					lat = lat_set[0].text
					lon = lon_set[0].text
					print(hospdata[i][0], hospdata[i][1], lat, lon)
					# Saves lat and long to data file
					hospdata[i].append(lat)
					hospdata[i].append(lon)
					hospdata[i].append('FOUND')
					curr_add = hospdata[i][addr_add]
				else:
					curr_add = hospdata[i][addr_add]
				time.sleep(0.8)
		else:
			print("*******")
			print("Stuff is missing!")
			print(i)
	elif hospdata[i][len(hospdata[i])-1] == 'FOUND':
		curr_add = hospdata[i][addr_add]
