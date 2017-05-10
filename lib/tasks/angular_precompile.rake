namespace :assets do
  desc "Compile webpack assets"
  task :webpack => [:environment] do
    require 'open3'
    our_path = File.expand_path(Rails.root)
    command_string = "cd #{our_path} && ./node_modules/.bin/webpack --color"
    stdin_and_stderr, status = Open3.capture2e(command_string)
    puts stdin_and_stderr
    unless status.success?
      raise "Webpack build failed.  Process exited with status: #{status.exitstatus}"
    end
  end
end

Rake::Task["assets:precompile"].enhance ["assets:webpack"]
Rake::Task["spec"].enhance ["assets:webpack"]
