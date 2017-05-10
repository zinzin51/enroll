# Enable factory_girl
World(FactoryGirl::Syntax::Methods)

# Compile our angular assets
AfterConfiguration do |config|
  our_path = File.expand_path(Rails.root)
  `cd #{our_path} && ./node_modules/.bin/webpack --color`
end
