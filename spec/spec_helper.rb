require 'rubygems'
require 'spec/autorun'
require 'active_record'

RAILS_ROOT = '.'
require File.join(File.dirname(__FILE__), '../lib/bullet/logger')
require File.join(File.dirname(__FILE__), '../lib/bullet/association')
require File.join(File.dirname(__FILE__), '../lib/bullet')
Bullet.enable = true
require File.join(File.dirname(__FILE__), '../lib/hack/active_record')
