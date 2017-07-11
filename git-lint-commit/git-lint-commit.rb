#!/usr/bin/env ruby
# frozen_string_literal: true

# git-lint-commit: Lint a commit message for common mistakes.

VERSION = "1.0.4"

def usage
  puts <<~EOS
    Usage:
      git lint-commit [commit|-]

    Arguments:
      If [commit] is supplied (either as a hash or other reference, like HEAD),
      then the requested commit message is linted.

      Otherwise, standard input is linted. Supplying - also causes
      the linter to read from standard input.
  EOS

  exit
end

def version
  puts "git-lint-commit version #{VERSION}."

  exit
end

def w(l, s)
  puts "W: Line #{l}: #{s}"
end

def e(l, s)
  puts "E: Line #{l}: #{s}"
end

usage if ARGV.include?("--help") || ARGV.include?("-h")
version if ARGV.include?("--version") || ARGV.include?("-h")

commit = ARGV.shift

lines = if commit && commit != "-"
          `git log --format=%B -n 1 #{commit}`
        else
          STDIN.read
        end.lines.map(&:chomp)

subject, *body = *lines

e 1, "Missing subject line" if subject.nil? || subject.empty?
w 2, "Missing commit body" if body&.all?(&:empty?)

if subject
  len = subject.size
  w 1, "Subject line too long (#{len} > 50)" if len > 50
  w 1, "Subject line should not end with a period" if subject.end_with?(".")
end

# don't bother linting the body if it's empty
return if body&.all?(&:empty?)

w 2, "An empty line should separate body and subject" unless body.first.empty?

lines.each_with_index do |line, i|
  next if i < 2
  next if line.start_with? "#"
  len = line.size
  w i.succ, "Body line too long (#{len} > 72)" if len > 72
end
