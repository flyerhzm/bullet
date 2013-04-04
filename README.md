# Bullet

[![Build Status](https://secure.travis-ci.org/flyerhzm/bullet.png)](http://travis-ci.org/flyerhzm/bullet)

[![Coderwall Endorse](http://api.coderwall.com/flyerhzm/endorsecount.png)](http://coderwall.com/flyerhzm)

The Bullet gem is designed to help you increase your application's performance by reducing the number of queries it makes. It will watch your queries while you develop your application and notify you when you should add eager loading (N+1 queries), when you're using eager loading that isn't necessary and when you should use counter cache.

Best practice is to use Bullet in development mode or custom mode (staging, profile, etc.). The last thing you want is your clients getting alerts about how lazy you are.

Bullet gem now supports **activerecord** 3.0, 3.1, 3.2, 4.0 and **mongoid** >= 2.4.1.

If you use activercord 2.x, please use bullet <= 4.5.0

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
gem "bullet", :group => "development"
```

## Configuration

Bullet won't do ANYTHING unless you tell it to explicitly. Append to
`config/environments/development.rb` initializer with the following code:

```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true 
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.growl = true
  Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
                  :password => 'bullets_password_for_jabber',
                  :receiver => 'your_account@jabber.org',
                  :show_online_status => true }
  Bullet.rails_logger = true
  Bullet.airbrake = true
end
```

The notifier of bullet is a wrap of [uniform_notifier](https://github.com/flyerhzm/uniform_notifier)

The code above will enable all seven of the Bullet notification systems:
* `Bullet.enable`: enable Bullet gem, otherwise do nothing
* `Bullet.alert`: pop up a JavaScript alert in the browser
* `Bullet.bullet_logger`: log to the Bullet log file (Rails.root/log/bullet.log)
* `Bullet.rails_logger`: add warnings directly to the Rails log
* `Bullet.airbrake`: add notifications to airbrake
* `Bullet.console`: log warnings to your browser's console.log (Safari/Webkit browsers or Firefox w/Firebug installed)
* `Bullet.growl`: pop up Growl warnings if your system has Growl installed. Requires a little bit of configuration
* `Bullet.xmpp`: send XMPP/Jabber notifications to the receiver indicated. Note that the code will currently not handle the adding of contacts, so you will need to make both accounts indicated know each other manually before you will receive any notifications. If you restart the development server frequently, the 'coming online' sound for the bullet account may start to annoy - in this case set :show_online_status to false; you will still get notifications, but the bullet account won't announce it's online status anymore.

Bullet also allows you to disable n_plus_one_query, unused_eager_loading
and counter_cache detectors respectively

```ruby
Bullet.n_plus_one_query_enable = false
Bullet.unused_eager_loading_enable = false
Bullet.counter_cache_enable = false
```

## Whitelist

Sometimes bullet may notify n plus one query, unused eager loading or
counter cache you don't care about or they occur in the third party gems
that you can't fix, you can add whitelist to bullet

```ruby
Bullet.add_whitelist :type => :n_plus_one_query, :class_name => "Post", :association => :comments
Bullet.add_whitelist :type => :unused_eager_loading, :class_name => "Post", :association => :comments
Bullet.add_whitelist :type => :counter_cache, :class_name => "Country", :association => :cities
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

If you find bullet does not work for you, *please disable your browser's cache*.

## Advance

The bullet gem use rack middleware for http request. If you want to bullet for without http server, such as job server. You can do like this:

```ruby
Bullet.start_request if Bullet.enable?
# run job
if Bullet.enable? && Bullet.notification?
  Bullet.perform_out_of_channel_notifications
end
Bullet.end_request if Bullet.enable?
```

Or you want to use it in test mode

```ruby
before(:each)
  Bullet.start_request if Bullet.enable?
end

after(:each)
  if Bullet.enable? && Bullet.notification?
    Bullet.perform_out_of_channel_notifications
  end
  Bullet.end_request if Bullet.enable?
end
```

Don't forget enabling bullet in test environment.

### API access

after `end_request`, you can fetch warnings then do whatever you want

```ruby
Bullet.start_request if Bullet.enable?
# run anything
if Bullet.enable? && Bullet.notification?
  Bullet.perform_out_of_channel_notifications
end
Bullet.end_request if Bullet.enable?
warnings = Bullet.warnings
```

## Contributors

[https://github.com/flyerhzm/bullet/contributors](https://github.com/flyerhzm/bullet/contributors)

## Step by step example

Bullet is designed to function as you browse through your application in development. It will alert you whenever it encounters N+1 queries or unused eager loading.

1\. setup test environment

```
$ rails new test_bullet
$ cd test_bullet
$ rails g scaffold post name:string
$ rails g scaffold comment name:string post_id:integer
$ bundle exec rake db:migrate
```

2\. change `app/model/post.rb` and `app/model/comment.rb`

```ruby
class Post < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
```

3\. go to `rails c` and execute

```ruby
post1 = Post.create(:name => 'first')
post2 = Post.create(:name => 'second')
post1.comments.create(:name => 'first')
post1.comments.create(:name => 'second')
post2.comments.create(:name => 'third')
post2.comments.create(:name => 'fourth')
```

4\. change the `app/views/posts/index.html.erb` to produce a N+1 query

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

5\. add bullet gem to `Gemfile`

```ruby
gem "bullet"
```

And run

```
bundle install
```

6\. enable the bullet gem in development, add a line to
`config/environments/development.rb`

```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
#  Bullet.growl = true
  Bullet.rails_logger = true
end
```

7\. start server

```
$ rails s
```

8\. input http://localhost:3000/posts in browser, then you will see a popup alert box says

```
The request has unused preload associations as follows:
None
The request has N+1 queries as follows:
model: Post => associations: [comment]
```

which means there is a N+1 query from post object to comments associations.

In the meanwhile, there's a log appended into `log/bullet.log` file

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

The generated SQLs are

```
Post Load (1.0ms)   SELECT * FROM "posts"
Comment Load (0.4ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 1)
Comment Load (0.3ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 2)
```


9\. fix the N+1 query, change `app/controllers/posts_controller.rb` file

```ruby
def index
  @posts = Post.includes(:comments)

  respond_to do |format|
    format.html # index.html.erb
    format.xml  { render :xml => @posts }
  end
end
```

10\. refresh http://localhost:3000/posts page, no alert box and no log appended.

The generated SQLs are

```
Post Load (0.5ms)   SELECT * FROM "posts"
Comment Load (0.5ms)   SELECT "comments".* FROM "comments" WHERE ("comments".post_id IN (1,2))
```

a N+1 query fixed. Cool!

11\. now simulate unused eager loading. Change
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

12\. refresh http://localhost:3000/posts page, then you will see a popup alert box says

```
The request has unused preload associations as follows:
model: Post => associations: [comment]
The request has N+1 queries as follows:
None
```

In the meanwhile, there's a log appended into `log/bullet.log` file

```
2009-08-25 21:13:22[INFO] Unused preload associations: PATH_INFO: /posts;    model: Post => associations: [comments]·
Remove from your finder: :include => [:comments]
```

13\. simulate counter_cache. Change `app/controllers/posts_controller.rb`
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

14\. refresh http://localhost:3000/posts page, then you will see a popup alert box says

```
Need counter cache
  Post => [:comments]
```

In the meanwhile, there's a log appended into `log/bullet.log` file.

```
2009-09-11 10:07:10[INFO] Need Counter Cache
  Post => [:comments]
```


Copyright (c) 2009 - 2013 Richard Huang (flyerhzm@gmail.com), released under the MIT license
