Little plugin for the [travis cli](https://github.com/travis-ci/travis#command-line-client) wrapping GitHub's [Repo Hooks API](http://developer.github.com/v3/repos/hooks/) to enable/disable pull request testing for a repository.

# Usage

You can check if pull request testing is currently enabled or disabled by running `travis pr` or `travis pr show`. You can disable/enable pull request testing by running `travis pr enable`/`travis pr disable`.

    $ travis pr
    Pull Request testing is currently enabled for travis-ci/travis.
    $ travis pr disable
    Pull Request testing has been disabled for travis-ci/travis.

If you are not running the command from within the project directory, add the `-r` option:

    $ travis pr disable -r travis-ci/travis
    Pull Request testing has been disabled for travis-ci/travis.


If you run this on Travis Enterprise, don't forget the `-X` version the first time you use this command on a repository.

    $ travis pr disable -r secret/project -X
    Pull Request testing has been disabled for travis-ci/travis.

# Installation

    $ git clone https://github.com/travis-ci/travis-cli-pr ~/.travis/travis-cli-pr

Or clone to anywhere and symlink to `~/.travis/travis-cli-pr`.
