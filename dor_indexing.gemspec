# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dor_indexing/version'

Gem::Specification.new do |spec|
  spec.name = 'dor_indexing'
  spec.version = DorIndexing::VERSION
  spec.authors = ['Justin Littman']
  spec.email = ['justinlittman@stanford.edu']

  spec.summary = 'Library for creating Solr documents for SDR indexing.'
  spec.description = 'Library for creating Solr documents for SDR indexing.'
  spec.homepage = 'https://github.com/sul-dlss/dor_indexing'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/dor_indexing'
  spec.metadata['changelog_uri'] = 'https://github.com/sul-dlss/folio_client/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cocina-models', '~> 0.94.0'
  spec.add_dependency 'honeybadger'
  spec.add_dependency 'marc-vocab', '~> 0.3.0'
  spec.add_dependency 'solrizer'
  spec.add_dependency 'stanford-mods'
  spec.add_dependency 'zeitwerk'
end
