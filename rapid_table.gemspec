# frozen_string_literal: true

require_relative "lib/rapid_table/version"

Gem::Specification.new do |spec|
  spec.name = "rapid_table"
  spec.version = RapidTable::VERSION
  spec.authors = ["Dan Cunning"]
  spec.email = ["dan@rapidlybuilt.com"]

  spec.summary = "RapidTable - A Ruby gem for building feature-rich data tables using ViewComponent."
  spec.description = "RapidTable is a comprehensive Ruby gem for building feature-rich data tables using ViewComponent."
  spec.homepage = "https://rapidlybuilt.com/tools/rapid-table"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rapidlybuilt/rapid_table"
  spec.metadata["changelog_uri"] = "https://github.com/rapidlybuilt/rapid_table/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  # spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "csv", ">= 3.0"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "view_component", ">= 4.0"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
