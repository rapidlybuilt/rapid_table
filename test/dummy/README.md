# README

Sandbox application demos the features of rapid_table for system tests

## Generated via

```bash
rails new sandbox --skip-git --skip-docker --skip-keeps --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-job --skip-jbuilder --skip-test --skip-system-test --skip-bootsnap --skip-dev-gems --skip-thruster --skip-rubocop --skip-brakeman --skip-ci --skip-kamal --skip-solid

cd sandbox
rm Gemfile Gemfile.lock
rm bin/bundle
rm bin/dev
rm config/environments/development.rb
rm config/environments/production.rb
```

Add this to the top of bin/rails
```
ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../../../Gemfile", __dir__)
```

```bash
bin/rails g rspec:install
```


Create bin/rspec
```bash
#!/usr/bin/env ruby
# This script runs rspec using the parent project's Gemfile

ENV['BUNDLE_GEMFILE'] = File.expand_path('../../../../Gemfile', __FILE__)
load File.expand_path('../../../../bin/rspec', __FILE__)
```

```bash
chmod +x bin/rspec
```

```bash
bin/rails g rapid_table:install
```