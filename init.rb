$:.unshift File.expand_path('../lib', __FILE__)
require 'travis/cli'

module Travis
  module CLI
    autoload :Pr, 'travis/cli/pr'
  end
end
