# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: github-rundeck
# GithubRunDeck:: CLI
#
# Copyright (C) 2017 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'mixlib/cli'
require 'github-rundeck/config'
require 'github-rundeck/util'

module GithubRunDeck
  #
  # => GitHub-RunDeck Launcher
  #
  module CLI
    module_function

    #
    # => Options Parser
    #
    class Options
      # => Mix-In the CLI Option Parser
      include Mixlib::CLI

      option :github_oauth_token,
             short: '-g TOKEN',
             long: '--github-oauth-token TOKEN',
             description: 'OAuth Token to use for querying GitHub'

      option :cache_timeout,
             short: '-t CACHE_TIMEOUT',
             long: '--timeout CACHE_TIMEOUT',
             description: 'Sets the cache timeout in seconds for API query response data.'

      option :config_file,
             short: '-c CONFIG',
             long: '--config CONFIG',
             description: 'The configuration file to use, as opposed to command-line parameters (optional)'

      option :bind,
             short: '-b HOST',
             long: '--bind HOST',
             description: "Listen on Interface or IP (Default: #{Config.bind})"

      option :port,
             short: '-p PORT',
             long: '--port PORT',
             description: "The port to run on. (Default: #{Config.port})"

      option :environment,
             short: '-e ENV',
             long: '--env ENV',
             description: "Sets the environment for deploy-info to execute under. Use 'development' for more logging. (Default: #{Config.environment})"
    end

    def configure(argv = ARGV)
      # => Parse CLI Configuration
      cli = Options.new
      cli.parse_options(argv)

      # => Parse JSON Config File (If Specified & Exists)
      json_config = Util.parse_json(cli.config[:config_file] || Config.config_file)

      # => Merge Configuration (CLI Wins)
      config = [json_config, cli.config].compact.reduce(:merge)

      # => Apply Configuration
      config.each { |k, v| Config.send("#{k}=", v) }
    end

    # => Launch the Application
    def run(argv = ARGV)
      # => Parse the Params
      configure(argv)

      # => Launch the API
      API.run!
    end
  end
end
