requires_gem 'jira'

setup do
  @jira_username     = config('jira.username', 'Your JIRA username', :local)
  @jira_password     = config('jira.password', 'Your JIRA Password', :local)
  @jira_url          = config('jira.url', 'Base URL if your JIRA instance', :local)
  @project_id        = config('jira.project-id', 'JIRA project key', :local)
  @jira_issue_filter = config('jira.issue-filter', 'Issue filter (in JQL)', :local, jira_default_issue_filter)
  @start_transition  = config('jira.start-transition', 'When starting, execute transition', :local, "Start Progress")
  @finish_transition = config('jira.finish-transition', 'When finished, execute transition', :local, "Resolve Issue")
  @jira_api          = JIRA::Client.new(username: @jira_username, 
                                        password: @jira_password, 
                                        site: @jira_url, 
                                        context_path: '',
                                        auth_type: :basic) 
end

before_start do
  @issue   = jira_select_issue
  @branch  = "#{@issue.issuetype.name.downcase}/#{@issue.key}-#{@issue.summary}"
  @title   = @issue.summary
  @summary = jira_generate_summary
end

after_start do
  jira_transition_start_progress @issue
end

before_finish do
  issue_id = branch.upcase.match(/.*\/(#{@project_id}-\d+)-.*/)[1]
  @issue   = @jira_api.Issue.jql("key = #{issue_id}").first
  @title   = @issue.summary
  @summary = jira_generate_summary
end

after_finish do
  jira_transition_finish_progress @issue
end

def jira_generate_summary
  <<-MARKDOWN.gsub(/^    /, '').gsub(/\n+/, "\n\n")
    # #{@issue.summary}
    #{@issue.description}
    <#{jira_issue_url(@issue)}>
  MARKDOWN
end

def jira_issues
  @jira_issues ||= @jira_api.Issue.jql(@jira_issue_filter)
end

def jira_default_issue_filter
  [
    "project = '#{@project_id}'",
    "assignee = currentUser()",
    "statusCategory = 'To Do'",
    "sprint in openSprints()"
  ].join " and "
end

def jira_select_issue
  existing_issues = jira_issues.map do |i|
    i.issuetype.name.upcase.ljust(9) + i.summary 
  end
  choice = select_one_of('Select story', existing_issues)

  abort "No valid issue selected." unless choice >= 0 and choice < jira_issues.length
  jira_issues[choice]
end

def jira_transition_start_progress(issue)
  jira_transition(issue, @start_transition)
end

def jira_transition_finish_progress(issue)
  jira_transition(issue, @finish_transition)
end

def jira_transition(issue, transition_name)
  transition = jira_find_transition(issue, transition_name)
  abort "Cannot find transition #{transition_name} for #{issue.key}" unless transition
  @jira_api.post("#{issue.self}/transitions", { transition: transition.id }.to_json )
end

def jira_find_transition(issue, transition_name)
  transitions = @jira_api.Transition.all(issue: issue)
  transitions.find { |t| t.name == transition_name }
end

def jira_issue_url(issue)
  "#{@jira_url}/browse/#{issue.key}"
end
