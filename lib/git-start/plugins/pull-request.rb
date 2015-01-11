include_plugin 'github'

after_finish do
  @github.create_pull_request @github_repo, 'master', branch, title, summary
end
