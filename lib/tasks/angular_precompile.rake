namespace :assets do
  desc "Compile webpack assets"
  task :webpack => [:environment] do
    our_path = File.expand_path(Rails.root)
    `cd #{our_path} && ./node_modules/.bin/webpack --color`
  end
end

Rake::Task["assets:precompile"].enhance ["assets:webpack"]
Rake::Task["spec"].enhance ["assets:webpack"]
