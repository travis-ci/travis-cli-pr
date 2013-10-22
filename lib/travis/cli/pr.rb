require 'travis/cli'
require 'travis/tools/token_finder'
require 'json'

module Travis
  module CLI
    class Pr < RepoCommand
      description "manage pull request testing for a repository"
      on '--github-token TOKEN', 'identify by GitHub token'
      on '-f', '--force-login', 'force a proper login handshake with github'

      attr_accessor :github_login, :github_password, :github_token, :github_otp

      def help
        super("\nAvailable subcommands: enable, disable, show\n")
      end

      def run(subcommand = 'show')
        error "unknown command %p" % subcommand unless %w[enable disable show].include? subcommand

        load_gh
        self.github_token   = generate_github_token if force_login?
        self.github_token ||= endpoint_config['pr_token']
        self.github_token ||= Travis::Tools::TokenFinder.find(:explode => explode?, :github => github_endpoint.host)
        self.github_token ||= generate_github_token
        GH.with(:token => github_token) { send(subcommand) }
        endpoint_config['pr_token'] = github_token
      end

      def show
        status = enabled? ? 'enabled' : 'disabled'
        say status, "Pull Request testing is currently %s for #{repository.slug}."
      end

      def disable
        GH.patch(link, :remove_events => ['pull_request']) if enabled?
        say "disabled", "Pull Request testing has been %s for #{repository.slug}."
      end

      def enable
        GH.patch(link, :add_events => ['pull_request']) unless enabled?
        say "enabled", "Pull Request testing has been %s for #{repository.slug}."
      end

      private

        def hook
          @hook ||= GH["/repos/#{repository.slug}/hooks"].detect { |h| h['name'] == 'travis' }
          error "GitHub hook not found. Project might not be enabled." unless @hook
          @hook
        end

        def link
          hook["_links"]["self"]["href"]
        end

        def enabled?
          hook['events'].include? 'pull_request'
        end

        def generate_github_token
          ask_info
          options           = { :username => github_login, :password => github_password }
          options[:headers] = { "X-GitHub-OTP" => github_otp } if github_otp
          gh                = GH.with(options)
          reply             = gh.post('/authorizations', :scopes => [org? ? 'public_repo' : 'repo'], :note => "token for enabling/disabling pull request testing")
          self.github_token = reply['token']
        rescue GH::Error => error
          if error.info[:response_status] == 401
            ask_2fa
            generate_github_token
          else
            raise error if explode?
            error(JSON.parse(error.info[:response_body])["message"])
          end
        end

        def ask_info
          return if !github_login.nil?
          say "We need your #{color("GitHub login", :important)} to identify you."
          say "This information will #{color("not be sent to Travis CI", :important)}, only to #{color(github_endpoint.host, :info)}."
          say "The password will not be displayed."
          empty_line
          say "Try running with #{color("--github-token", :info)} if you don't want to enter your password anyway."
          empty_line
          self.github_login    = ask("Username: ")
          self.github_password = ask("Password: ") { |q| q.echo = "*" }
          empty_line
        end

        def ask_2fa
          self.github_otp = ask "Two-factor authentication code: "
          empty_line
        end
    end
  end
end
