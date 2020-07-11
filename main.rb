#!/bin/ruby

require 'rubygems'
require 'octokit'

class Repository
  VALIDATION_ERROR = ['Action requires a GITHUB_REPOSITORY environment variable',
                      "with current repo path (f.e. 'owner/repo')"].join(' ').freeze

  def initialize(source)
    @source = source
  end

  def to_s
    "#{owner}/#{repo}"
  end

  def validate!
    return self if valid?

    raise(VALIDATION_ERROR)
  end

  class << self
    def from(source)
      repository_cls(source).new(source).validate!
    end

    private

    def repository_cls(source)
      case source
      when String then Env
      when Hash then Payload
      else Nil
      end
    end
  end

  class Env < Repository
    def valid?
      split_source.size >= 2
    end

    def owner
      split_source.first
    end

    def repo
      split_source.last
    end

    private

    def split_source
      @split_source ||= @source.split('/')
    end
  end

  class Payload < Repository
    def valid?
      @source.key?('name') && @source.key?('owner') && @source['owner'].key?('login')
    end

    def owner
      @source['owner']['login']
    end

    def repo
      @source['name']
    end
  end

  class Nil
    def valid?
      false
    end
  end
end

class Payload
  EMPTY_JSON = '{}'.freeze

  def [](key)
    payload[key]
  end

  private

  def payload
    @payload ||= parse
  end

  def parse
    return {} unless path

    JSON.parse(file_contents)
  end

  def path
    ENV['GITHUB_EVENT_PATH']
  end

  def file_contents
    return File.read(path) if File.exist?(path)

    puts("GITHUB_EVENT_PATH #{path} does not exist")
    EMPTY_JSON
  end
end

class Context
  attr_reader :payload, :event_name, :sha, :ref, :workflow, :action, :actor

  def initialize
    @payload = Payload.new
    @event_name = ENV['GITHUB_EVENT_NAME']
    @sha = ENV['GITHUB_SHA']
    @ref = ENV['GITHUB_REF']
    @workflow = ENV['GITHUB_WORKFLOW']
    @action = ENV['GITHUB_ACTION']
    @actor = ENV['GITHUB_ACTOR']
  end

  def repository
    @repository ||= Repository.from(ENV['GITHUB_REPOSITORY'] || @payload['repository'])
  end
end

ACTION_NAME = 'duderman/gh-gem-tag-action@v1'
SHA = ENV['GITHUB_SHA']
TAG_TYPE = 'commit'.freeze
DEBUG_MSG_PREFIX = '::debug::'.freeze

def debug(msg)
  log DEBUG_MSG_PREFIX + msg
end

def log(msg)
  puts msg
end

class ArgIsMissing < StandardError
  attr_reader :arg_name

  def initialize(arg_name)
    @arg_name = arg_name
  end

  def message
    %Q('#{arg_name}' parameter is missing.

Set it as a step parameter. F.e:

- name: Tag it
  uses: #{ACTION_NAME}
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    tag_prefix: v
)
  end
end

def set_ouput(name, value)
  puts "::set-output name=#{name}::#{value}"
end

gh_token = ARGV[0] || raise(ArgIsMissing, 'github_token')
tag_prefix = ARGV[2]

debug "Running action with: token = '#{gh_token}', " \
      "tag_prefix: '#{tag_prefix}'"

current_dir = ENV.fetch('GITHUB_WORKSPACE', '.')
gemspec = Dir.entries(current_dir).detect { |file| File.extname(file) == '.gemspec' } || raise('.gemspec file not found')
spec = Gem::Specification::load(gemspec)
debug "Version from gemspec: #{spec.version}"

context = Context.new
octokit = Octokit::Client.new(access_token: gh_token)

commit = octokit.commit(context.repository.to_s, context.sha)
author = commit.commit.commiter

debug "Commit author: #{author.name} <#{author.email}> @ #{author.date}"

tag_name = "#{tag_prefix}#{spec.version}"
debug "Creating a tag '#{tag_name}' for repo '#{context.repository}' at #{context.sha}"
tag = octokit.create_tag(context.repository.to_s, tag_name, context.sha, TAG_TYPE, author.name, author.email, author.date)
log "Created new tag: #{tag.tag}"
set_ouput('tag', tag.tag)

ref_name = "refs/tags/#{tag.tag}"
debug "Creating a ref '#{ref_name}' for sha #{tag.sha}"
ref = octokit.create_ref(context.repository.to_s, ref_name, tag.sha)
log "Ref #{ref.ref} created and available at #{ref.url}"
set_ouput('url', ref.url)
