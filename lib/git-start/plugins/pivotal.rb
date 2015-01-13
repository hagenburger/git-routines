requires_gem 'tracker_api'

# TrackerApi does not support saving yet
class ::TrackerApi::Client
  def put(path, options = {})
    request(:put, parse_query_and_convenience_headers(path, options))
  end
end

setup do
  @story_types = { f: :feature, b: :bug, c: :chore }
  @tracker_token = config('pivotal.token', 'Your PivotalTracker API token', :global)
  @user_initials = config('pivotal.user', 'Your PivotalTracker user initials', :global).upcase
  @project_id = config('pivotal.project', 'PivotalTracker project ID (last part of URL)', :local)
  @tracker = TrackerApi::Client.new(token: @tracker_token)
  @project = @tracker.project(@project_id)
  @user_id = user_id_of(@user_initials)
end

before_start do
  select_story
  @branch = "#{@story.story_type.downcase}/#{@story.id}-#{@story.name}"
  @title = @story.name
  @summary = generate_summary
end

after_start do
  update_story @story.id, current_state: :started
end

before_finish do
  @story_id = branch.match(/(?<=feature\/|chore\/|bug\/)(\d+)(?=-)/).to_s.to_i
  @story = @project.story(@story_id)
  @title = @story.name
  @summary = generate_summary
end

after_finish do
  update_story @story.id, current_state: :finished
end


def generate_summary
  <<-MARKDOWN.gsub(/^    /, '').gsub(/\n+/, "\n\n")
    # #{@story.name}
    #{@story.description}
    #{@story.tasks.map{ |t| "  * #{t.description}" }.join("\n") rescue ''}
    <#{@story.url}>
  MARKDOWN
end

def stories
  @stories ||= @project.stories(filter: filter, limit: 999)
end

def filter
  "current_state:unscheduled,unstarted,rejected mywork:#{@user_initials}"
end

def select_story
  existing_stories = stories.map do |s|
    s.story_type.upcase.ljust(9) + s.name
  end
  new_story_types = @story_types.inject({}) do |h, (key, type)|
    h.update(key => type.to_s.upcase.ljust(9) + "Create new #{type} story")
  end
  choice = select_one_of('Select story', existing_stories, new_story_types)

  if @story_types.has_key?(choice)
    @story = create_story(@story_types[choice])
  else
    if choice >= 0 and choice < stories.length
      @story = stories[choice]
    else
      abort "No valid story selected."
    end
  end
  estimate if needs_estimation?
end

def needs_estimation?
  @story.estimate.nil? &&
  @story.story_type == 'feature' || @project.bugs_and_chores_are_estimatable
end

def estimate
  scale = @project.point_scale.gsub(',', ', ')
  estimate = ask_for("This story needs an estimate first [#{scale}]")
  update_story @story.id, estimate: estimate
end

def update_story(id, attributes)
  @tracker.put "/projects/#{@project_id}/stories/#{id}", params: attributes
end

def user_id_of(initials)
  membership = @project.memberships.detect{ |m| m.person.initials == initials }
  if membership.nil?
    abort "User with initials #{initials} not found for this project."
  end
  membership.person.id
end

def create_story(type)
  params = {
    name: ask_for('Story title'),
    description: ask_for('Story description'),
    requested_by_id: requester_id,
    owner_ids: [@user_id],
    story_type: type
  }
  data = @tracker.post("/projects/#{@project_id}/stories", params: params).body
  TrackerApi::Resources::Story.new({ client: @client }.merge(data))
end

def requester_id
  question = 'Story requester initials'
  initials = config('pivotal.requester', question, :local, @user_initials).upcase
  user_id_of(initials)
end
