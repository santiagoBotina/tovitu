class Result
  attr_reader :data, :errors, :error_code

  def initialize(success:, data: nil, errors: [], error_code: nil)
    @success = success
    @data = data
    @errors = Array(errors)
    @error_code = error_code
    freeze
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def on_success
    yield(data) if success?
    self
  end

  def on_failure
    yield(errors, error_code) if failure?
    self
  end

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(errors, error_code: nil)
    new(success: false, errors: errors, error_code: error_code)
  end
end
