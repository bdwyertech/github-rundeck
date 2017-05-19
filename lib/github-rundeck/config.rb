# Encoding: UTF-8
#
# Gem Name:: github-rundeck
# GithubRunDeck:: Config
#
# Copyright (C) 2017 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'github-rundeck/helpers/configuration'
require 'pathname'

module GithubRunDeck
  # => This is the Configuration module.
  module Config
    module_function

    extend Configuration

    # => Gem Root Directory
    define_setting :root, Pathname.new(File.expand_path('../../../', __FILE__))

    # => My Name
    define_setting :author, 'Brian Dwyer - Intelligent Digital Services'

    # => Application Environment
    define_setting :environment, :production

    # => Sinatra Configuration
    define_setting :port, '9123'
    define_setting :bind, 'localhost'
    define_setting :cache_timeout, 30

    # => Config File
    define_setting :config_file, File.join(root, 'config', 'config.json')

    #
    # => API Configuration
    #
    # => Github OAuth Token
    define_setting :github_oauth_token

    #
    # => Facilitate Dynamic Addition of Configuration Values
    #
    # => @return [class_variable]
    #
    def add(config = {})
      config.each do |key, value|
        define_setting key.to_sym, value
      end
    end

    #
    # => Facilitate Dynamic Removal of Configuration Values
    #
    # => @return nil
    #
    def clear(config)
      Array(config).each do |setting|
        delete_setting setting
      end
    end

    #
    # => List the Configurable Keys as a Hash
    #
    # @return [Hash]
    #
    def options
      map = Config.class_variables.map do |key|
        [key.to_s.tr('@', '').to_sym, class_variable_get(:"#{key}")]
      end
      Hash[map]
    end
  end
end
