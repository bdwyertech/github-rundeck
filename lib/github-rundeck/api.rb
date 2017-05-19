# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: github-rundeck
# GithubRunDeck:: API
#
# Copyright (C) 2017 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

# => NOTE: Anything other than a STATUS 200 will trigger an error in the RunDeck plugin due to a hardcode in org.boon.HTTP

require 'sinatra/base'
require 'sinatra/namespace'
require 'json'
require 'rack/cache'
require 'github-rundeck/config'
require 'github-rundeck/git'
require 'github-rundeck/util'

# => Deployment Information Provider for RunDeck
module GithubRunDeck
  # => HTTP API
  class API < Sinatra::Base
    #######################
    # =>    Sinatra    <= #
    #######################

    # => Configure Sinatra
    enable :logging, :static, :raise_errors # => disable :dump_errors, :show_exceptions
    set :port, Config.port || 8080
    set :bind, Config.bind || 'localhost'
    set :environment, Config.environment.to_sym.downcase || :production

    # => Enable NameSpace Support
    register Sinatra::Namespace

    if development?
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    use Rack::Cache do
      set :verbose, true
      set :metastore,   'file:' + File.join(Dir.tmpdir, 'rack', 'meta')
      set :entitystore, 'file:' + File.join(Dir.tmpdir, 'rack', 'body')
    end

    ########################
    # =>    JSON API    <= #
    ########################

    # => Current Configuration & Healthcheck Endpoint
    if development?
      get '/config' do
        content_type 'application/json'
        JSON.pretty_generate(
          [
            GithubRunDeck.inspect + ' is up and running!',
            'Author: ' + Config.author,
            'Environment: ' + Config.environment.to_s,
            'Root: ' + Config.root.to_s,
            'Config File: ' + (Config.config_file if File.exist?(Config.config_file)).to_s,
            'Params: ' + params.inspect,
            'Cache Timeout: ' + Config.cache_timeout.to_s,
            { AppConfig: Config.options },
            { 'Sinatra Info' => env }
          ].compact
        )
      end
    end

    ########################
    # =>    JSON API    <= #
    ########################

    namespace '/github/v1' do # rubocop: disable BlockLength
      # => Define our common namespace parameters
      before do
        # => This is a JSON API
        content_type 'application/json'

        # => Make the Params Globally Accessible
        Config.define_setting :query_params, params

        # => Parameter Overrides
        Github.configure do |cfg|
          cfg.oauth_token = params['gh_oauth_token'] || Config.github_oauth_token
        end
      end

      # => Clean Up
      after do
        # => Reset the API Client to Default Values
        # => Notifier.reset!
      end

      # => Get Organization Repo List
      get '/repos/org/:org' do |org|
        ghresponse = Git.repos.list(org: org, per_page: 100)
        etag ghresponse.headers.etag
        body Util.serialize(ghresponse)
      end

      # => Get User Repo List
      get '/repos/user/:user' do |user|
        ghresponse = Git.repos.list(user: user, per_page: 100)
        etag ghresponse.headers.etag
        body Util.serialize(ghresponse)
      end

      # => Get Branch/Tag Names
      get '/revisions/:user/:repo' do |user, repo|
        branches = Git.repos.branches(user: user, repo: repo, per_page: 100)
        tags = Git.repos.tags(user: user, repo: repo, per_page: 100)
        body Util.serialize_revisions(branches, tags)
      end

      # => Compare Branch/Tags
      get '/compare/:user/:repo' do |user, repo|
        # => Check Parameters - Default to Master
        refs = [
          { 'target' => params['ref1'] || 'master' },
          { 'target' => params['ref2'] || 'master' }
        ]

        begin
          refs.each do |ref|
            # => Pull the SHA
            ref['sha'] = ghclient.git_data.trees.get(user, repo, ref['target']).first[1]
          end

          if refs[0]['sha'] == refs[1]['sha']
            return "ref1(#{user}/#{repo}/#{refs[0]['target']}) is the same as ref2(#{user}/#{repo}/#{refs[1]['target']})".to_json
          else
            status 500 unless params['errorok'] == '1'
            return "ALERT!!! - ref1(#{user}/#{repo}/#{refs[0]['target']}) is different than ref2(#{user}/#{repo}/#{refs[1]['target']})".to_json
          end

        # => Catch any GitHub Errors
        rescue Github::Error::GithubError => e
          status 500 unless params['errorok'] == '1'
          e.message.to_json
        end
      end
    end
  end
end
