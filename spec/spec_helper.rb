require 'rubygems'
require 'spec/autorun'
require 'active_record'

RAILS_ROOT = File.expand_path(__FILE__).split('/')[0..-6].join('/') unless defined? RAILS_ROOT
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/logger'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/active_record'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/association'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet'))
Bullet.enable = true
