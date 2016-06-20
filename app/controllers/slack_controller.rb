require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'trollop'
gem 'google-api-client', '<0.9'
require 'google/api_client'

DEVELOPER_KEY = 'AIzaSyAex_E6FGQVwPSc7owkYh0T_bWYkbQJhaY' #'REPLACE_ME'
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'

def get_service
        client = Google::APIClient.new(
          :key => DEVELOPER_KEY,
          :authorization => nil,
          :application_name => $PROGRAM_NAME,
          :application_version => '1.0.0'
        )
        youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

        return client, youtube
end

def main(busqueda)
  puts 'entro a main'
  opts = Trollop::options do
    opt :q, 'Search term', :type => String, :default => busqueda
    opt :max_results, 'Max results', :type => :int, :default => 5
  end

  client, youtube = get_service

  begin
    puts 'entro a begin'
    # Call the search.list method to retrieve results matching the specified
    # query term.
    search_response = client.execute!(
      :api_method => youtube.search.list,
      :parameters => {
        :part => 'snippet',
        :q => opts[:q],
        :maxResults => opts[:max_results]
      }
    )

    videos = []
    channels = []
    playlists = []

    # Add each result to the appropriate list, and then display the lists of
    # matching videos, channels, and playlists.
    search_response.data.items.each do |search_result|
      case search_result.id.kind
        when 'youtube#video'
          videos << "#{search_result.snippet.title} (#{search_result.id.videoId})"
        when 'youtube#channel'
          channels << "#{search_result.snippet.title} (#{search_result.id.channelId})"
        when 'youtube#playlist'
          playlists << "#{search_result.snippet.title} (#{search_result.id.playlistId})"
      end
    end

    puts "Videos:\n", videos, "\n"
    puts "Channels:\n", channels, "\n"
    puts "Playlists:\n", playlists, "\n"
    #postear(videos)
    return videos.to_s
    #final = { :posts =>videos }
    #  render json: final.to_json, status: 200
  rescue Google::APIClient::TransmissionError => e
    puts e.result.body
  end
end
def start
  rc = HTTP.post("https://slack.com/api/rtm.start", params:{
    token: 'SLACK_API_TOKEN'
    })
  rc = JSON.parse(rc.body)
  #puts rc
  url = rc['url']

  EM.run do
    ws = Faye::WebSocket::Client.new(url)
    ws.on :open do
      p [:open]
    end

    ws.on :message do |event|
      #puts main
      puts 'entre'
      p [:message, JSON.parse(event.data)]
      data = JSON.parse(event.data)
      if data['text'] != nil
        ws.send({type:'message',
          text: "5 videos con la palabra clave son: \n" + main(data['text']),
          channel: data['channel'] }.to_json )
      end
    end

    ws.on :close do
      p [:close, event.code]
      ws = nil
      EM.stop
    end
  end
end
=begin
      DEVELOPER_KEY = 'AIzaSyAex_E6FGQVwPSc7owkYh0T_bWYkbQJhaY' #'REPLACE_ME'
      YOUTUBE_API_SERVICE_NAME = 'youtube'
      YOUTUBE_API_VERSION = 'v3'
      Slack.configure do |config|
        config.token = ENV['xoxb-52286720133-FwF6uGjRKheF8eVev90YPPIh']
        puts 'hola'
        puts config.token
      end

      client = Slack::RealTime::Client.new
      puts client

      client.on :hello do
        puts 'entre'
        puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      end

      client.on :message do |data|
        case data.text
        when 'bot hi' then
          client.message channel: data.channel, text: "Hi <@#{data.user}>!"
        when /^bot/ then
          client.message channel: data.channel, text: "Sorry <@#{data.user}>, what?"
        end
      end

      client.on :close do |_data|
        puts "Client is about to disconnect"
      end

      client.on :closed do |_data|
        puts "Client has disconnected successfully!"
      end

      client.start!
=end
