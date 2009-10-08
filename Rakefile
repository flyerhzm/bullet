require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'jeweler'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Generate documentation for the sitemap plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Bullet'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "bullet"
  gemspec.summary = "A plugin to kill N+1 queries and unused eager loading"
  gemspec.description = "The Bullet plugin is designed to help you increase your application's performance by reducing the number of queries it makes. It will watch your queries while you develop your application and notify you when you should add eager loading (N+1 queries) or when you're using eager loading that isn't necessary."
  gemspec.email = "flyerhzm@gmail.com"
  gemspec.homepage = "http://github.com/flyerhzm/bullet"
  gemspec.authors = ["Richard Huang"]
  gemspec.files.exclude '.gitignore'
  gemspec.files.exclude 'log/*'
end
Jeweler::GemcutterTasks.new
