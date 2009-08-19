require 'rubygems'
require 'spec/autorun'
require 'active_record'

RAILS_ROOT = File.expand_path(__FILE__).split('/')[0..-3].join('/')
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/logger'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/association'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet'))
Bullet.enable = true
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/hack/active_record'))
