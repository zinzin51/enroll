# Enable factory_girl
World(FactoryGirl::Syntax::Methods)

# Compile our angular assets
AfterConfiguration do |config|
  require 'open3'
  our_path = File.expand_path(Rails.root)
  command_string = "cd #{our_path} && ./node_modules/.bin/webpack --color"
  stdin_and_stderr, status = Open3.capture2e(command_string)
  puts stdin_and_stderr
  unless status.success?
    raise "Webpack build failed.  Process exited with status: #{status.exitstatus}"
  end
end
