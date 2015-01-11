before_finish do
  git :checkout, default_branch
  git :pull
  git :checkout, branch
  git :rebase, default_branch
  git :push, 'origin', branch, :force
end
