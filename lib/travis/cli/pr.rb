require 'travis/cli'

module Travis
  module CLI
    class Pr < RepoCommand
      description "manage pull request testing for a repository"
      on '--github-token TOKEN', 'identify by GitHub token'
      on '-f', '--force-login', 'force a proper login handshake with github'

      def run(subcommand = 'show')
        error "requires cli version 1.6.4 or newer" if Travis::VERSION < "1.6.4" and not skip_version_check?
        error "unknown command %p" % subcommand unless %w[enable disable show signature token].include? subcommand
        github.with_session do |token|
          send subcommand
          endpoint_config['pr_token'] = token
        end
      end

      def github
        @github ||= begin
          load_gh
          require 'travis/tools/github'
          Tools::Github.new(session.config['github']) do |g|
            g.note           = "token for travis-cli-pr"
            g.github_token   = github_token
            g.github_token ||= endpoint_config['pr_token'] unless force_login?
            g.auto_token     = !force_login?
            g.auto_password  = !force_login?
            g.ask_login      = proc { ask("Username: ") }
            g.ask_password   = proc { |user| ask("Password for #{user}: ") { |q| q.echo = "*" } }
            g.ask_otp        = proc { |user| ask("Two-factor authentication code for #{user}: ") }
            g.login_header   = proc { say "You need to log in on #{color(github_endpoint.host, :info)}." }
            g.debug          = proc { |log| debug(log) }
            g.after_tokens   = proc { g.explode = true and error("no suitable github token found") }
          end
        end
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

      def token
        say hook["config"]["token"], "Travis CI token used for #{repository.slug}: %s"
      end

      def signature
        require 'digest/sha2'
        signature = Digest::SHA2.hexdigest(repository.slug + hook["config"]["token"])
        say signature, "Signature used for #{repository.slug} web hooks: %s"
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
    end
  end
end
