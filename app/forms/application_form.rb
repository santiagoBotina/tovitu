class ApplicationForm
  include ActiveModel::API
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  def persist
    raise NotImplementedError, "#{self.class} must implement #persist"
  end
end
