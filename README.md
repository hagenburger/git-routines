# Git-Start

`git start`—a Git workflow helper that:

* Shows all your PivotalTracker stories
* Creates feature/bug/chore branches for a chosen story
  **Bonus:** you can also create a new story in the command line
* Sets the story started

`git finish`—to call after you finished the story:

* Sets the story finished
* Rebases the current branch to your *master* branch
* Pushes the branch
* Opens a GitHub pull request (incl. link to the corresponding PivotalTracker story)
* Checks out *master*

## Setup

1. [Configure GitHub](https://github.com/blog/180-local-github-config)
2. `git config --global pivotal.api-token yourapitoken`
   (see <https://www.pivotaltracker.com/help/faq#wherecanifindmyapitoken>)
3. `git config --global pivotal.user yi`
   (your initials as set in PivotalTracker)
4. `git config start.type pivotal`
5. `git config start.pivotal-project 12345`
   (the ID as in your project URL http⁣://pivotaltracker.com/n/projects/**12345**)
6. `git config start.pivotal-requester xy`
   (the initials of the requester of new stories—this could be set to your product owner)
7. `git config start.base master`
   (your base branch)
8. `git config start.rebase true`
   (if you want to rebase to your base branch before pushing)
9. `git config start.pull-request true`
   (if you want to generate a pull request)
