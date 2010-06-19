require 'rake'
require 'rspec/core/rake_task'
require 'rake/rdoctask'
require 'jeweler'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Generate documentation for the bullet plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Bullet'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

RSpec::Core::RakeTask.new(:spec)

desc "Run all examples using rcov"
RSpec::Core::RakeTask.new :rcov => :cleanup_rcov_files do |t|
  t.rcov = true
  t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,spec/spec_helper.rb"]
  t.rcov_opts << %[--no-html --aggregate coverage.data]
end

task :cleanup_rcov_files do
  rm_rf 'coverage.data'
end

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

begin
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "bullet"
    gemspec.summary = "A rails plugin to kill N+1 queries and unused eager loading"
    gemspec.description = "The Bullet plugin is designed to help you increase your application's performance by reducing the number of queries it makes. It will watch your queries while you develop your application and notify you when you should add eager loading (N+1 queries) or when you're using eager loading that isn't necessary."
    gemspec.email = "flyerhzm@gmail.com"
    gemspec.homepage = "http://github.com/flyerhzm/bullet"
    gemspec.authors = ["Richard Huang"]
    gemspec.files.exclude '.gitignore'
    gemspec.files.exclude 'log/*'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
