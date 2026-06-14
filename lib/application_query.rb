class ApplicationQuery
  def self.call(...)
    new(...).call
  end

  def initialize(...)
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end
end
