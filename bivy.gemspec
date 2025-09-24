# frozen_string_literal: true

require_relative "lib/bivy/version"

Gem::Specification.new do |spec|
  spec.name = "bivy"
  spec.version = Bivy::VERSION
  spec.authors = ["Hans Lemuet"]
  spec.email = ["hans@etamin.studio"]

  spec.summary = "Quick-pitch Rails content indexing that adapts to any search terrain. Set up camp on Algolia (and more) with lightweight setup."
  spec.description = "Bivy simplifies ActiveRecord content indexing across multiple search engines. It provides a unified interface for Algolia, Typesense, and other providers, letting you switch or support multiple engines without rewriting indexing code."
  spec.homepage = "https://github.com/Spone/bivy"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "activejob", ">= 7.0"
  spec.add_dependency "zeitwerk", "~> 2.7"

  spec.add_development_dependency "activerecord", ">= 7.0"
  spec.add_development_dependency "sqlite3", "~> 2.7"
end
