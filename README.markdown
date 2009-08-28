*Please note!* This is the Bullet gem as written by Richard Huang, with a few added niceties:

- It has been refactored to support Rails initializers
- Growl, console.log, and Rails.logger support have been added

# Bullet #

The Bullet plugin is designed to help you increase your application's performance by reducing the number of queries it makes. It will watch your queries while you develop your application and notify you when you should add eager loading (N+1 queries) or when you're using eager loading that isn't necessary.

Best practice is to use Bullet while building your application, but UNINSTALL OR DEACTIVATE IT when you deploy to a production server. The last thing you want is your clients getting alerts about how lazy you are.

## Installation ##

### Get the source ##

You can add Bullet to your Rails gem requirements:

	config.gem 'flipsasser-bullet', :lib => nil, :source => 'http://gems.github.com'

Or you can install it as a gem like so:

	sudo gem install flipsasser-bullet --source http://gems.github.com

Finally, you can install it as a Rails plugins:

	ruby script/plugin install git://github.com/flipsasser/bullet.git

### Configure Bullet ###

Bullet boots up from a Rails initializer. It won't do ANYTHING unless you tell it to explicitly. Add a RAILS_ROOT/config/initializers/bullet.rb initializer with the following code:

	# Only use Bullet in development...
	if Bullet.enable = RAILS_ENV == 'development'
		Bullet::Association.alert = true
		Bullet::Association.bullet_logger = true  
		Bullet::Association.console = true
		Bullet::Association.growl = true
		Bullet::Association.rails_logger = true
	end

The code above will enable all five of the Bullet notification systems:

- `Bullet::Association.alert`: pop up a JavaScript alert in the browser
- `Bullet::Association.bullet_logger`: log to the Bullet log file (RAILS_ROOT/log/bullet.log)
- `Bullet::Association.rails_logger`: add warnings directly to the Rails log
- `Bullet::Association.console`: log warnings to your browser's console.log (Safari/Webkit browsers or Firefox w/Firebug installed)
- `Bullet::Association.growl`: pop up Growl warnings if your system has Growl installed. Requires a little bit of configuration

### The Bullet log ###

The Bullet log (log/bullet.log) will look something like this:

	2009-08-25 20:40:17[INFO] N+1 Query: PATH_INFO: /posts;    model: Post => associations: [comments]·
	Add to your finder: :include => [:comments]
	2009-08-25 20:40:17[INFO] N+1 Query: method call stack:·
	/Users/richard/Downloads/test/app/views/posts/index.html.erb:11:in `_run_erb_app47views47posts47index46html46erb'
	/Users/richard/Downloads/test/app/views/posts/index.html.erb:8:in `each'
	/Users/richard/Downloads/test/app/views/posts/index.html.erb:8:in `_run_erb_app47views47posts47index46html46erb'
	/Users/richard/Downloads/test/app/controllers/posts_controller.rb:7:in `index'

The first two lines are notifications that N+1 queries have been encountered. The remaining lines are stack traces so you can find exactly where the queries were invoked in your code, and fix them.

Bullet also has a Rake task, `rake bullet:log:clear`, which will clear out the Bullet log.

### Growl Support ###

To get Growl support up-and-running for Bullet, follow the steps below:

1. Install the ruby-growl gem: `sudo gem install ruby-growl`
2. Open the Growl preference pane in Systems Preferences
3. Click the "Network" tab
4. Make sure both "Listen for incoming notifications" and "Allow remote application registration" are checked. *Note:* If you set a password, you will need to set `Bullet::Association.growl_password = 'your_growl_password'` in the initializer.
5. Restart Growl ("General" tab -> Stop Growl -> Start Growl)
6. Boot up your application. Bullet will automatically send a Growl notification when Growl is turned on. If you do not see it when your application loads, make sure it is enabled in your initializer and double-check the steps above.

## Step by step example ##

Bullet is designed to function as you browse through your application in development. It will alert you whenever it encounters N+1 queries or unused eager loading.

*Important*: It is strongly recommended you disable your browser's cache.

1. Setup your test environment

	$ rails test
	$ cd test
	$ script/generate scaffold post name:string 
	$ script/generate scaffold comment name:string post_id:integer
	$ rake db:migrate

2. Add relationships to `app/model/post.rb` and `app/model/comment.rb`

	class Post < ActiveRecord::Base
		has_many :comments
	end

	class Comment < ActiveRecord::Base
		belongs_to :post
	end

3. Go to script/console and execute

	post1 = Post.create(:name => 'first')
	post2 = Post.create(:name => 'second')
	post1.comments.create(:name => 'first')
	post1.comments.create(:name => 'second')
	post2.comments.create(:name => 'third')
	post2.comments.create(:name => 'fourth')

4. Change the `app/views/posts/index.html.erb` to produce an N+1 query

	<% @posts.each do |post| %>
		<tr>
			<td><%= h post.name %></td>
			<td><%= post.comments.collect(&:name) %></td>
			<td><%= link_to 'Show', post %></td>
			<td><%= link_to 'Edit', edit_post_path(post) %></td>
			<td><%= link_to 'Destroy', post, :confirm => 'Are you sure?', :method => :delete %></td>
		</tr>
	<% end %>

5. Install the Bullet plugin

	$ script/plugin install git://github.com/flipsasser/bullet.git

6. Enable the bullet plugin in development with a Rails initializer (RAILS_ROOT/config/intializers/bullet.rb):

	if Bullet.enable = RAILS_ENV == 'development'
		Bullet::Association.alert = true
	end

7. Boot up your development server

	$ script/server 

8. Visit http://localhost:3000/posts in your browser. Bullet will alert you that an N+1 query has occurred.

	The request has N+1 queries as follows:
	model: Post => associations: [comment]

... which means there is an N+1 query from the Post object to the comments association.

9. Fix the N+1 query. Change `app/controllers/posts_controller.rb`:

	def index
		@posts = Post.find(:all, :include => :comments)

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @posts }
		end
	end

10. Refresh your browser. No alert should show up.

This is because the original query, which read:

	Post Load (1.0ms)   SELECT * FROM "posts" 
	Comment Load (0.4ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 1) 
	Comment Load (0.3ms)   SELECT * FROM "comments" WHERE ("comments".post_id = 2) 

... would cause one additional query for each post it found. The new SQL should look like this:

	Post Load (0.5ms)   SELECT * FROM "posts" 
	Comment Load (0.5ms)   SELECT "comments".* FROM "comments" WHERE ("comments".post_id IN (1,2)) 

And your N+1 query is fixed. Cool!

11. Now simulate unused eager loading. Change `app/controllers/posts_controller.rb` and `app/views/posts/index.html.erb`

app/controllers/posts_controller.rb:

	def index
		@posts = Post.find(:all, :include => :comments)

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @posts }
		end 
	end 

app/views/posts/index.html.erb:

	<% @posts.each do |post| %>
		<tr>
			<td><%=h post.name %></td>
			<td><%= link_to 'Show', post %></td>
			<td><%= link_to 'Edit', edit_post_path(post) %></td>
			<td><%= link_to 'Destroy', post, :confirm => 'Are you sure?', :method => :delete %></td>
		</tr>
	<% end %>

12. Refresh your browser. Bullet will alert you that you have unused, eager-loaded objects.

	The request has unused preload associations as follows:
	model: Post => associations: [comment]

Copyright (c) 2009 Richard Huang (flyerhzm@gmail.com), released under the MIT license.