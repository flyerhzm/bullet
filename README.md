# Bullet

[![Gem Version](https://badge.fury.io/rb/bullet.png)](http://badge.fury.io/rb/bullet)
[![Build Status](https://secure.travis-ci.org/flyerhzm/bullet.png)](http://travis-ci.org/flyerhzm/bullet)
[![AwesomeCode Status](https://awesomecode.io/projects/6755235b-e2c1-459e-bf92-b8b13d0c0472/status)](https://awesomecode.io/projects/2)
[![Coderwall Endorse](http://api.coderwall.com/flyerhzm/endorsecount.png)](http://coderwall.com/flyerhzm)

The Bullet gem is designed to help you increase your application's performance by reducing the number of queries it makes. It will watch your queries while you develop your application and notify you when you should add eager loading (N+1 queries), when you're using eager loading that isn't necessary and when you should use counter cache.

Best practice is to use Bullet in development mode or custom mode (staging, profile, etc.). The last thing you want is your clients getting alerts about how lazy you are.

Bullet gem now supports **activerecord** >= 4.0 and **mongoid** >= 4.0.

If you use activerecord 2.x, please use bullet <= 4.5.0

If you use activerecord 3.x, please use bullet < 5.5.0

## External Introduction

* [http://railscasts.com/episodes/372-bullet](http://railscasts.com/episodes/372-bullet)
* [http://ruby5.envylabs.com/episodes/9-episode-8-september-8-2009](http://ruby5.envylabs.com/episodes/9-episode-8-september-8-2009)
* [http://railslab.newrelic.com/2009/10/23/episode-19-on-the-edge-part-1](http://railslab.newrelic.com/2009/10/23/episode-19-on-the-edge-part-1)
* [http://weblog.rubyonrails.org/2009/10/22/community-highlights](http://weblog.rubyonrails.org/2009/10/22/community-highlights)

## Install

You can install it as a gem:

```
gem install bullet
```

or add it into a Gemfile (Bundler):


```ruby
gem 'bullet', group: 'development'
```

**Note**: make sure `bullet` gem is added after activerecord (rails) and
mongoid.

## Configuration

Bullet won't do ANYTHING unless you tell it to explicitly. Append to
`config/environments/development.rb` initializer with the following code:

```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.sentry = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.growl = true
  Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
                  :password => 'bullets_password_for_jabber',
                  :receiver => 'your_account@jabber.org',
                  :show_online_status => true }
  Bullet.rails_logger = true
  Bullet.honeybadger = true
  Bullet.bugsnag = true
  Bullet.airbrake = true
  Bullet.rollbar = true
  Bullet.add_panel = true
  Bullet.panel_position = 'bottom-left'
  Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
  Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware' ]
  Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
end
```

The notifier of Bullet is a wrap of [uniform_notifier](https://github.com/flyerhzm/uniform_notifier)

The code above will enable all of the Bullet notification systems:
* `Bullet.enable`: enable Bullet gem, otherwise do nothing
* `Bullet.alert`: pop up a JavaScript alert in the browser
* `Bullet.bullet_logger`: log to the Bullet log file (Rails.root/log/bullet.log)
* `Bullet.console`: log warnings to your browser's console.log (Safari/Webkit browsers or Firefox w/Firebug installed)
* `Bullet.growl`: pop up Growl warnings if your system has Growl installed. Requires a little bit of configuration
* `Bullet.xmpp`: send XMPP/Jabber notifications to the receiver indicated. Note that the code will currently not handle the adding of contacts, so you will need to make both accounts indicated know each other manually before you will receive any notifications. If you restart the development server frequently, the 'coming online' sound for the Bullet account may start to annoy - in this case set :show_online_status to false; you will still get notifications, but the Bullet account won't announce it's online status anymore.
* `Bullet.rails_logger`: add warnings directly to the Rails log
* `Bullet.honeybadger`: add notifications to Honeybadger
* `Bullet.bugsnag`: add notifications to bugsnag
* `Bullet.airbrake`: add notifications to airbrake
* `Bullet.rollbar`: add notifications to rollbar
* `Bullet.sentry`: add notifications to sentry
* `Bullet.add_panel`: adds the details in the bottom left corner of the page by default. Double click the panel or use close button to hide panel.
*  Bullet.panel_position : set the panel position, possible values are : bottom-left, bottom-right, top-left, top-right
* `Bullet.stacktrace_includes`: include paths with any of these substrings in the stack trace, even if they are not in your main app
* `Bullet.stacktrace_excludes`: ignore paths with any of these substrings in the stack trace, even if they are not in your main app.
* `Bullet.slack`: add notifications to slack
* `Bullet.raise`: raise errors, useful for making your specs fail unless they have optimized queries


Bullet also allows you to disable any of its detectors.

```ruby
# Each of these settings defaults to true

# Detect N+1 queries
Bullet.n_plus_one_query_enable     = false

# Detect eager-loaded associations which are not used
Bullet.unused_eager_loading_enable = false

# Detect unnecessary COUNT queries which could be avoided
# with a counter_cache
Bullet.counter_cache_enable        = false
```

## Whitelist

Sometimes Bullet may notify you of query problems you don't care to fix, or
which come from outside your code. You can whitelist these to ignore them:

```ruby
Bullet.add_whitelist :type => :n_plus_one_query, :class_name => "Post", :association => :comments
Bullet.add_whitelist :type => :unused_eager_loading, :class_name => "Post", :association => :comments
Bullet.add_whitelist :type => :counter_cache, :class_name => "Country", :association => :cities
```

If you want to skip bullet in some specific controller actions, you can
do like

```ruby
class ApplicationController < ActionController::Base
  around_action :skip_bullet

  def skip_bullet
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = true
  end
end
```

## Log

The Bullet log `log/bullet.log` will look something like this:

* N+1 Query:

```
2009-08-25 20:40:17[INFO] N+1 Query: PATH_INFO: /posts;    model: Post => associations: [comments]·
Add to your finder: :include => [:comments]
2009-08-25 20:40:17[INFO] N+1 Query: method call stack:·
/Users/richard/Downloads/test/app/views/posts/index.html.erb:11:in `_run_erb_app47views47posts47index46html46erb'
/Users/richard/Downloads/test/app/views/posts/index.html.erb:8:in `each'
/Users/richard/Downloads/test/app/views/posts/index.html.erb:8:in `_run_erb_app47views47posts47index46html46erb'
/Users/richard/Downloads/test/app/controllers/posts_controller.rb:7:in `index'
```

The first two lines are notifications that N+1 queries have been encountered. The remaining lines are stack traces so you can find exactly where the queries were invoked in your code, and fix them.

* Unused eager loading:

```
2009-08-25 20:53:56[INFO] Unused eager loadings: PATH_INFO: /posts;    model: Post => associations: [comments]·
Remove from your finder: :include => [:comments]
```

These two lines are notifications that unused eager loadings have been encountered.

* Need counter cache:

```
2009-09-11 09:46:50[INFO] Need Counter Cache
  Post => [:comments]
```

## Growl, XMPP/Jabber and Airbrake Support

see [https://github.com/flyerhzm/uniform_notifier](https://github.com/flyerhzm/uniform_notifier)

## Important

If you find Bullet does not work for you, *please disable your browser's cache*.

## Advanced

### Profile a job

The Bullet gem uses rack middleware to profile requests. If you want to use Bullet without an http server, like to profile a job, you can use the profile method and fetch warnings

```ruby
Bullet.profile do
  # do anything

  warnings = Bullet.warnings
end
```

### Work with sinatra

Configure and use `Bullet::Rack`

```ruby
configure :development do
  Bullet.enable = true
  Bullet.bullet_logger = true
  use Bullet::Rack
end
```

### Run in tests

First you need to enable Bullet in test environment.

```ruby
# config/environments/test.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.bullet_logger = true
  Bullet.raise = true # raise an error if n+1 query occurs
end
```

Then wrap each test in Bullet api.

```ruby
# spec/spec_helper.rb
if Bullet.enable?
  config.before(:each) do
    Bullet.start_request
  end

  config.after(:each) do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end
```

## Debug Mode

Bullet outputs some details info, to enable debug mode, set
`BULLET_DEBUG=true` env.

## Contributors

[https://github.com/flyerhzm/bullet/contributors](https://github.com/flyerhzm/bullet/contributors)

## Demo

Bullet is designed to function as you browse through your application in development. To see it in action,
you can visit [https://github.com/flyerhzm/bullet_test](https://github.com/flyerhzm/bullet_test) or
follow these steps to create, detect, and fix example query problems.

1\. Create an example application

```
$ rails new test_bullet
$ cd test_bullet
$ rails g scaffold post name:string
$ rails g scaffold comment name:string post_id:integer
$ bundle exec rake db:migrate
```

2\. Change `app/model/post.rb` and `app/model/comment.rb`

```ruby
class Post < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
```

3\. Go to `rails c` and execute

```ruby
post1 = Post.create(:name => 'first')
post2 = Post.create(:name => 'second')
post1.comments.create(:name => 'first')
post1.comments.create(:name => 'second')
post2.comments.create(:name => 'third')
post2.comments.create(:name => 'fourth')
```

4\. Change the `app/views/posts/index.html.erb` to produce a N+1 query

```
<% @posts.each do |post| %>
  <tr>
    <td><%= post.name %></td>
    <td><%= post.comments.map(&:name) %></td>
    <td><%= link_to 'Show', post %></td>
    <td><%= link_to 'Edit', edit_post_path(post) %></td>
    <td><%= link_to 'Destroy', post, :confirm => 'Are you sure?', :method => :delete %></td>
  </tr>
<% end %>
```

5\. Add the `bullet` gem to the `Gemfile`

```ruby
gem "bullet"
```

And run

```
bundle install
```

6\. enable the Bullet gem with generate command

```
bundle exec rails g bullet:install
```

7\. Start the server

```
$ rails s
```

8\. Visit `http://localhost:3000/posts` in browser, and you will see a popup alert box that says

```
The request has unused preload associations as follows:
None
The request has N+1 queries as follows:
model: Post => associations: [comment]
```

which means there is a N+1 query from the Post object to its Comment association.

In the meantime, there's a log appended into `log/bullet.log` file

```
2010-03-07 14:12:18[INFO] N+1 Query in /posts
  Post => [:comments]
  Add to your finder: :include => [:comments]
2010-03-07 14:12:18[INFO] N+1 Query method call stack
  /home/flyerhzm/Downloads/test_bullet/app/views/posts/index.html.erb:14:in `_render_template__600522146_80203160_0'
  /home/flyerhzm/Downloads/test_bullet/app/views/posts/index.html.erb:11:in `each'
  /home/flyerhzm/Downloads/test_bullet/app/views/posts/index.html.erb:11:in `_render_template__600522146_80203160_0'
  /home/flyerhzm/Downloads/test_bullet/app/controllers/posts_controller.rb:7:in `index'
```

The generated SQL is:

```
Post Load (1.0ms)   SELECT * FROM "posts"
Comment Load (0.4ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 1)
Comment Load (0.3ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 2)
```

9\. To fix the N+1 query, change `app/controllers/posts_controller.rb` file

```ruby
def index
  @posts = Post.includes(:comments)

  respond_to do |format|
    format.html # index.html.erb
    format.xml  { render :xml => @posts }
  end
end
```

10\. Refresh `http://localhost:3000/posts`. Now there's no alert box and nothing new in the log.

The generated SQL is:

```
Post Load (0.5ms)   SELECT * FROM "posts"
Comment Load (0.5ms)   SELECT "comments".* FROM "comments" WHERE ("comments".post_id IN (1,2))
```

N+1 query fixed. Cool!

11\. Now simulate unused eager loading. Change
`app/controllers/posts_controller.rb` and
`app/views/posts/index.html.erb`

```ruby
def index
  @posts = Post.includes(:comments)

  respond_to do |format|
    format.html # index.html.erb
    format.xml  { render :xml => @posts }
  end
end
```

```
<% @posts.each do |post| %>
  <tr>
    <td><%= post.name %></td>
    <td><%= link_to 'Show', post %></td>
    <td><%= link_to 'Edit', edit_post_path(post) %></td>
    <td><%= link_to 'Destroy', post, :confirm => 'Are you sure?', :method => :delete %></td>
  </tr>
<% end %>
```

12\. Refresh `http://localhost:3000/posts`, and you will see a popup alert box that says

```
The request has unused preload associations as follows:
model: Post => associations: [comment]
The request has N+1 queries as follows:
None
```

Meanwhile, there's a line appended to `log/bullet.log`

```
2009-08-25 21:13:22[INFO] Unused preload associations: PATH_INFO: /posts;    model: Post => associations: [comments]·
Remove from your finder: :include => [:comments]
```

13\. Simulate counter_cache. Change `app/controllers/posts_controller.rb`
and `app/views/posts/index.html.erb`

```ruby
def index
  @posts = Post.all

  respond_to do |format|
    format.html # index.html.erb
    format.xml  { render :xml => @posts }
  end
end
```

```
<% @posts.each do |post| %>
  <tr>
    <td><%= post.name %></td>
    <td><%= post.comments.size %></td>
    <td><%= link_to 'Show', post %></td>
    <td><%= link_to 'Edit', edit_post_path(post) %></td>
    <td><%= link_to 'Destroy', post, :confirm => 'Are you sure?', :method => :delete %></td>
  </tr>
<% end %>
```

14\. Refresh `http://localhost:3000/posts`, then you will see a popup alert box that says

```
Need counter cache
  Post => [:comments]
```

Meanwhile, there's a line appended to `log/bullet.log`

```
2009-09-11 10:07:10[INFO] Need Counter Cache
  Post => [:comments]
```

Copyright (c) 2009 - 2016 Richard Huang (flyerhzm@gmail.com), released under the MIT license
