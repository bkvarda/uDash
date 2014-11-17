# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
require 'rest_client'
require 'json'
require 'nokogiri'

$creds = 'username:password'
$utorrentapi = 'IP AND Port - IE 192.168.1.50:8080'
$tokenuri = 'http://'+$creds+'@'+$utorrentapi+'/gui/token.html'

def get_utorrent_token
tokenarray = [2]
response =  RestClient.get $tokenuri
page = Nokogiri::HTML(response.body)
tokenarray[0] =  response.headers[:set_cookie]
tokenarray[1] =  page.css('div#token')[0].text
return tokenarray
end


def get_utorrent_build
tokenarray = get_utorrent_token
cookie = tokenarray[0]
token = tokenarray[1]
uri = 'http://'+$creds+'@'+$utorrentapi+'/gui/?token='+token
response = RestClient.get uri, {:Cookie => cookie}
data = JSON.parse(response)
return data["build"]
end

def get_number_of_torrents
tokenarray = get_utorrent_token
cookie = tokenarray[0]
token = tokenarray[1]
uri = 'http://'+$creds+'@'+$utorrentapi+'/gui/?token='+token+'&list=1'
response = RestClient.get uri, {:Cookie => cookie}
data = JSON.parse(response)
return data["torrents"].count
end


def get_number_of_movies
tokenarray = get_utorrent_token
cookie = tokenarray[0]
token = tokenarray[1]
uri = 'http://'+$creds+'@'+$utorrentapi+'/gui/?token='+token+'&list=1'
response = RestClient.get uri, {:Cookie => cookie}
data = JSON.parse(response)
return data['label'][0][1]
end


def get_number_of_shows
tokenarray = get_utorrent_token
cookie = tokenarray[0]
token = tokenarray[1]
uri = 'http://'+$creds+'@'+$utorrentapi+'/gui/?token='+token+'&list=1'
response = RestClient.get uri, {:Cookie => cookie}
data = JSON.parse(response)
return data['label'][1][1]
end

def get_list_of_downloads
tokenarray = get_utorrent_token
cookie = tokenarray[0]
token = tokenarray[1]
uri = 'http://'+$creds+'@'+$utorrentapi+'/gui/?token='+token+'&list=1'
response = RestClient.get uri, {:Cookie => cookie}
data = JSON.parse(response)
torrentdata = data["torrents"]
downloadarray = []
  torrentdata.each do |torrent|
   if torrent[21]=='Downloading'
    downloadarray.push(torrent)
   end
  end

downloadfilteredarray = []
  downloadarray.each do |torrent|
   torname = torrent[2]
   amtdown = torrent[5].to_f
   torsize = torrent[3].to_f
   percentcomp = (amtdown / torsize).round(2)
   torpercent = percentcomp * 100
   temparray = []
   temparray.push(torname)
   temparray.push(torpercent)
   downloadfilteredarray.push(temparray)
  end
 return downloadfilteredarray
end





SCHEDULER.every '10s', :first_in => 0 do |job|
  downloadlist = get_list_of_downloads
  send_event('welcome', { text: 'Utorrent build: '+get_utorrent_build.to_s })
  send_event('numshows', { value: get_number_of_shows })
  send_event('nummovies', { value: get_number_of_movies })
  send_event('numdownloads', {value: get_list_of_downloads.count })
  downloadhash = Hash.new({ value: 0 })
  downloadlist.each do |download|
  downloadhash[download[0]] = { label: download[0], value: download[1].to_s+'%' }
   end
  send_event('downloads', { items: downloadhash.values })

end



