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
  t.spec_files = FileList['spec/spec_helper.rb', 'spec/**/*_spec.rb']
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "bullet"
  gemspec.summary = "A plugin to kill N+1 queries and unused eager loading"
  gemspec.description = "This plugin is aimed to give you some performance suggestion about ActiveRecord usage, what should use but not use, such as eager loading, counter cache and so on, what should not use but use, such as unused eager loading. Now it provides you the suggestion of eager loading and unused eager loading. The others are todo, next may be couter cache."
  gemspec.email = "flyerhzm@gmail.com"
  gemspec.homepage = "http://www.huangzhimin.com/projects/4-bullet"
  gemspec.authors = ["Richard Huang"]
  gemspec.files.exclude '.gitignore'
  gemspec.files.exclude 'log/'
end
