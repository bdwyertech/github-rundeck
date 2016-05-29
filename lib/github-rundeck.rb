# encoding: UTF-8
# rubocop: disable LineLength
# GitHub Repo Poller for RunDeck
# Brian Dwyer - Intelligent Digital Services - 5/14/16

require 'sinatra/base'
require 'sinatra/namespace'
require 'github_api'
require 'json'
require 'rack/cache'

# => GitHub RunDeck
class GithubRunDeck < Sinatra::Base
  register Sinatra::Namespace
  class Error < StandardError
  end

  class << self
    attr_accessor :config_file
    attr_accessor :cache_timeout
    attr_accessor :github_oauth_token
  end

  if development?
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  def self.app_name
    'github-rundeck'
  end

  ######################
  # =>  Definitions  <=#
  ######################

  def ghclient
    # => Instantiate a new GitHub Client
    Github::Client::Repos.new
  end

  def serialize(response)
    # => Serialize Object into JSON Array
    JSON.pretty_generate(response.map(&:name).sort_by(&:downcase))
  end

  def serialize_revisions(branches, tags)
    # => Serialize Branches/Tags into JSON Array
    # => Branches = String, Tags = Key/Value
    branches = branches.map(&:name).sort_by(&:downcase)
    tags = tags.map(&:name).sort_by(&:downcase).reverse.map { |tag| { name: "Tag: #{tag}", value: tag } }
    JSON.pretty_generate(branches + tags)
  end

  ######################
  # =>    Sinatra    <=#
  ######################

  use Rack::Cache do
    set :verbose, true
    set :metastore,   'file:' + File.join(Dir.tmpdir, 'rack', 'meta')
    set :entitystore, 'file:' + File.join(Dir.tmpdir, 'rack', 'body')
  end

  # => Current Configuration & Healthcheck Endpoint
  get '/' do
    content_type 'text/plain'
    <<-EOS.gsub(/^\s+/, '')
      #{GithubRunDeck.app_name} is up and running!
      :config_file = #{GithubRunDeck.config_file}
      :cache_timeout = #{GithubRunDeck.cache_timeout}
      :github_oauth_token = #{!GithubRunDeck.github_oauth_token.nil?}
      :params = #{params.inspect}
    EOS
    puts ENV['rack-cache']
  end

  #######################
  # =>    JSON API    <=#
  #######################

  namespace '/github/v1' do
    # => Define our common namespace parameters
    before do
      # => This is a JSON API
      content_type 'application/json'

      # => Cache GitHub Responses for 30 Seconds
      cache_control :public, max_age: 30

      # => Parameter Overrides
      Github.configure do |cfg|
        cfg.oauth_token = params['oauth_token'] || GithubRunDeck.github_oauth_token
      end
    end

    # => Get Organization Repo List
    get '/repos/org/:org' do |org|
      ghresponse = ghclient.with(org: org).list(per_page: 100)
      etag ghresponse.headers.etag
      body serialize(ghresponse)
    end

    # => Get User Repo List
    get '/repos/user/:user' do |user|
      ghresponse = ghclient.with(user: user).list(per_page: 100)
      etag ghresponse.headers.etag
      body serialize(ghresponse)
    end

    # => Get Branch/Tag Names
    get '/revisions/:user/:repo' do |user, repo|
      branches = ghclient.with(user: user, repo: repo).branches
      tags = ghclient.with(user: user, repo: repo).tags
      body serialize_revisions(branches, tags)
    end
  end
end
