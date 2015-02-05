requires_gem 'octokit'

setup do
  remote_url = config('remote.origin.url')
  @github_repo = remote_url.match(/(?<=:).+(?=\.git)/).to_s
  @github_token = config('github.token', 'Your GitHub API token')
  @github = Octokit::Client.new(access_token: @github_token)
end
