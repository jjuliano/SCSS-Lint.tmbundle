#!/usr/bin/env ruby

begin
  require 'scss_lint'
  require 'scss_lint/cli'
  require 'json'
rescue LoadError
  puts "Install scss_lint!\ngem install scss_lint"
  exit 1
end

def log(msg)
  require 'logger'
  logger = Logger.new('/tmp/scss_lint_bundle.log')
  logger.info msg
end

def offences(file)
  io = StringIO.new
  logger = SCSSLint::Logger.new(io)
  SCSSLint::CLI.new(logger).run(['--format', 'JSON', file])
  offence = JSON.parse(io.string)
  offence[file]
end

def messages(offences)
  messages = {
    warning: {},
    error: {}
  }
  offences.each do |offence|
    severity = offence["severity"].to_sym
    line = offence["line"]
    message = messages[severity][line] ||= []
    message << offence["reason"].gsub('`', "'").gsub(',', ' ')
  end
  messages
end

def command(messages)
  icons = {
    warning:    "#{ENV['TM_BUNDLE_SUPPORT']}/neutral.png".inspect,
    error:      "#{ENV['TM_BUNDLE_SUPPORT']}/sad.png".inspect
  }
  args = []

  messages.each do |severity, messages|
    args << ["--clear-mark=#{icons[severity]}"]
    messages.each do |line, message|
      args << "--set-mark=#{icons[severity]}:#{message.uniq.join(' ').inspect}"
      args << "--line=#{line}"
    end
  end

  args << ENV['TM_FILEPATH'].inspect

  "#{ENV['TM_MATE']} #{args.join(' ')}"
end

cmd = command(messages(offences(ENV['TM_FILEPATH'])))

# log cmd
exec cmd
