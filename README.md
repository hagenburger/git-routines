# Git-Start

`git start`—a Git workflow helper that:

* Shows all your PivotalTracker stories
* Creates feature/bug/chore branches for a chosen story
  **Bonus:** you can also create a new story in the command line
* Sets the story started
* _Optional:_ Outputs a summary of the story to the command line

`git finish`—to call after you finished the story:

* Sets the story finished
* _Optional:_ Rebases the current branch to your *master* branch
* Pushes the branch
* _Optional:_ Opens a GitHub pull request (incl. link to the corresponding PivotalTracker story)
* Checks out *master*


## Setup

```
gem install git-start
```

Other configuration happens on the fly. All information will be requested when needed.
