# frozen_string_literal: true

require_relative "lib/encomium/version"

Gem::Specification.new do |spec|
  spec.name          = "encomium"
  spec.version       = Encomium::VERSION
  spec.authors       = ["Steve Meyer"]
  spec.email         = ["stephen.meyer@wisc.edu"]

  spec.summary       = "Analyze institutional citation patterns."
  spec.homepage      = "https://www.library.wisc.edu"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://gems.library.wisc.edu"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "marc", "~> 1.0.4"
  spec.add_dependency "data_stream", "~> 0.1.0"
end
