require 'base64'
require 'openssl'
require 'nokogiri'
require 'rest-client'
require 'json'

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
      final = {:metadata =>{:total => total}, :posts =>postArray }
        render json: final.to_json, status: 200
      rescue Exception => e
        exception = ''
        render json: exception.to_json, status: 400
      end
end
