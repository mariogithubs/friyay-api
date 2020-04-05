#!/usr/bin/env ruby

# Set the default Pry editor
#
# Example Usage:
#
# $ require 'active_support/all'
# $ edit ActiveSupport.on_load => (open the ActiveSupport class file in the specified editor, at the line where the method is defined)
#
Pry.config.editor = proc { |file, line| "vim #{file}:#{line}" }
