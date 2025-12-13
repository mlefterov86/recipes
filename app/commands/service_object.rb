# frozen_string_literal: true

# Wrapper methods to build service objects
module ServiceObject
  attr_reader :result

  # Methods exposed to every class prepending ServiceObject
  module ClassMethods
    def call(*, **, &)
      new(*, **).call(&)
    end
  end

  def self.prepended(base)
    base.extend ClassMethods
  end

  def call(*args, **kwargs)
    raise NotImplementedError unless defined?(super)

    @result = super
    self
  rescue ExitError
    self
  end

  def success?
    errors.none?
  end

  def failure?
    !success?
  end

  def errors
    @errors ||= Errors.new
  end

  def abort(*args)
    args.each { |arg| errors.add(arg) }
    raise ExitError
  end

  # Error class callable with #errors method
  # The notion of success or failure from the caller of the class using ServiceObject is based of the errors presence/absence
  class Errors < Array
    def add(*messages)
      messages.each { |message| self << message }
    end

    # Returns a hash with the first two elements of the array
    # to use if only when at least two elements have been added with #add or #abort method
    # eg: abort(:email, :invalid, 'The provided email is invalid')
    # errors.as_hash => { email: :invalid }
    def as_hash
      Hash[*self[..1]]
    end

    # Returns the last element of the array
    # eg: abort(:email, :invalid, 'The provided email is invalid')
    # errors.message => 'The provided email is invalid'
    def message
      self[-1]
    end

    # Returns the error code and key joined together as a symbol
    # eg: abort(:email, :invalid, 'The provided email is invalid')
    # errors.as_key => :email_invalid
    def as_key
      self[..1].join("_").to_sym
    end

    # Returns the number of errors
    # warning: use this method only if the errors are added with error code and key
    # eg: abort(:email, :invalid, 'The provided email is invalid')
    # errors.count => 1
    def count
      select { |element| element.is_a?(Symbol) }
        .each_slice(2)
        .count
    end
  end

  class ExitError < StandardError; end
end
