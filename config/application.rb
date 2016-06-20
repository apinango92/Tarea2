require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'trollop'
gem 'google-api-client', '<0.9'
require 'google/api_client'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RubyGettingStarted
  class Application < Rails::Application

    config.after_initialize do

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
          token: 'xoxb-52286720133-rWTHcaQzfm77pbFNTB7cBrN9'
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
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
