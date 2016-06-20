require 'coveralls'
Coveralls.wear!
require 'base64'
require 'openssl'
require 'nokogiri'
require 'rest-client'
require 'json'
require 'rubygems'
gem 'google-api-client', '<0.9'
require 'google/api_client'
require 'trollop'
require 'slack-ruby-bot'
#require 'celluloid/current'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception

  def tag
      puts 'pase'
      tag = params[:tag].to_s
      access_token = params[:access_token].to_s
      url1 = 'https://api.instagram.com/v1/tags/'
      url2 = '/media/recent?access_token='
      url3 = '?access_token='
      urlPost = url1 + tag + url2 + access_token
      urlMetadata = url1 + tag + url3 + access_token
      puts urlPost
      puts urlMetadata
      posts = RestClient.get urlPost
      metadata = RestClient.get urlMetadata
      #puts posts
      #puts metadata
      my_hash = JSON.parse(metadata)
      total = my_hash["data"]["media_count"]

      post_hash = JSON.parse(posts)
      tags = Array.new(post_hash["data"].length)
      username = Array.new(post_hash["data"].length)
      likes = Array.new(post_hash["data"].length)
      url  = Array.new(post_hash["data"].length)
      caption = Array.new(post_hash["data"].length)
      postArray = Array.new(post_hash["data"].length)
      for i in 0..post_hash["data"].length-1
        #puts 'entre'
        tags[i] = post_hash["data"][i]["tags"]
        username[i] = post_hash["data"][i]["user"]["username"]
        likes[i] = Integer(post_hash["data"][i]["likes"]["count"] || '')
        url[i] = post_hash["data"][i]["images"]["standard_resolution"]["url"]
        caption[i] = post_hash["data"][i]["caption"]["text"]
        post = Hash.new
        post["tags"] = tags[i]
        post["username"] = username[i]
        post["likes"] = likes[i]
        post["url"] = url[i]
        post["caption"] = caption[i]
        postArray[i] = post
      end
      puts postArray
      puts tags[0]
      puts username[0]
      puts likes[0]
      puts url[0]
      puts caption[0]
      final = {:metadata =>{:total => total}, :posts =>postArray , :version => '1.0.1'}
        render json: final.to_json, status: 200
        rescue Exception => e
        exception = ''
        render json: exception.to_json, status: 400
  end

  def postear (videos)
    puts 'hola'
    url = 'https://hooks.slack.com/services/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'
    #posts = RestClient.post url, :payload => {"text": "This is a line of text in a channel.\nAnd this is another line of text."}.to_json
    posts = RestClient.post url, :payload => {"text": videos.to_s }.to_json
    puts posts
    #final = { :posts =>posts }
    #  render json: final.to_json, status: 200
  end

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

      def main
        opts = Trollop::options do
          opt :q, 'Search term', :type => String, :default => 'gato'
          opt :max_results, 'Max results', :type => :int, :default => 5
        end

        client, youtube = get_service

        begin
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
          postear(videos)
          final = { :posts =>videos }
            render json: final.to_json, status: 200
        rescue Google::APIClient::TransmissionError => e
          puts e.result.body
        end
      end
end
