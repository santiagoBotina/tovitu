class ApplicationPresenter < SimpleDelegator
  def initialize(model)
    @model = model
    super(model)
  end

  private

  attr_reader :model
end
