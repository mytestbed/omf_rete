#$:.unshift((File.dirname(__FILE__)) + '../../lib').unshift(File.dirname(__FILE__) + '..')

require 'test/unit'

Dir.glob("#{File.dirname(__FILE__)}/test_*.rb").each do |fn|
  load fn
end

