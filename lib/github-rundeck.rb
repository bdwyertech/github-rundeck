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

  class << self
    attr_accessor :config_file
    attr_accessor :cache_timeout
    attr_accessor :github_oauth_token
  end

  if development?
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  VERSION = '0.1.1'.freeze

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
    content_type 'application/json'
    JSON.pretty_generate(
      Status: "#{self.class} is up and running!",
      ConfigFile: GithubRunDeck.config_file,
      CacheTimeout: GithubRunDeck.cache_timeout,
      GithubOAuthToken: GithubRunDeck.github_oauth_token,
      Params: params.inspect
    )
  end

  #######################
  # =>    JSON API    <=#
  #######################

  namespace '/github/v1' do
    # => Define our common namespace parameters
    before do
      # => This is a JSON API
      content_type 'application/json'

      # => Cache GitHub Responses
      cache_control :public, max_age: GithubRunDeck.cache_timeout || 30

      # => Parameter Overrides
      Github.configure do |cfg|
        cfg.oauth_token = params['oauth_token'] || GithubRunDeck.github_oauth_token
      end
    end

    # => Get Organization Repo List
    get '/repos/org/:org' do |org|
      ghresponse = ghclient.list(org: org, per_page: 100)
      etag ghresponse.headers.etag
      body serialize(ghresponse)
    end

    # => Get User Repo List
    get '/repos/user/:user' do |user|
      ghresponse = ghclient.list(user: user, per_page: 100)
      etag ghresponse.headers.etag
      body serialize(ghresponse)
    end

    # => Get Branch/Tag Names
    get '/revisions/:user/:repo' do |user, repo|
      branches = ghclient.branches(user: user, repo: repo)
      tags = ghclient.tags(user: user, repo: repo)
      body serialize_revisions(branches, tags)
    end
  end
end
