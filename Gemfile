source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'
gem 'jquery-rails'

gem 'mysql2', '>= 0.3'

gem 'haml'
gem 'sass', :tag => '3.0.24'
gem 'kaminari' #for pagination
gem 'simple_form', :git => 'git://github.com/plataformatec/simple_form.git'

gem 'thin'

gem 'acts_as_tree', :git => 'https://github.com/parasew/acts_as_tree.git'

gem "cancan"
gem 'devise'
gem 'sunspot_rails'
gem 'sunspot_solr'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem "ruby-debug-base19x"
  gem "ruby-debug-ide"
  gem "nifty-generators"
  gem 'mongrel', '>= 1.2.0.pre2' #for ruby v1.9.2
  gem 'progress_bar' # for sunspot
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.2.0"
  gem 'coffee-rails', "~> 3.2.0"
  gem 'uglifier', '>= 1.0.3'
  gem 'bootstrap-sass', :git => 'https://github.com/thomas-mcdonald/bootstrap-sass.git', :branch => '2.0'
  gem 'bootstrap-will_paginate'
  #gem 'compass'#, ">= 0.11.beta.3"
end
