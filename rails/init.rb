# Include hook code here
require 'bullet'
require 'hack/active_record'
ActionController::Dispatcher.middleware.use Bulletware
