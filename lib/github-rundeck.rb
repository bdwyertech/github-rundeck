# encoding: UTF-8
# rubocop: disable LineLength
# GitHub Repo Poller for RunDeck
# Brian Dwyer - Intelligent Digital Services - 5/14/16

require 'github-rundeck/cli'

# => GitHub RunDeck Options Provider API
module GithubRunDeck
  # => The Sinatra API should be Lazily-Loaded, such that the CLI arguments and/or configuration files are respected
  autoload :API, 'github-rundeck/api'
end
