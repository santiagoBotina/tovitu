module ApplicationHelper
  def present(model)
    presenter_class = "#{model.class}Presenter".safe_constantize
    return model unless presenter_class

    presenter_class.new(model)
  end

  def safe_url(url)
    return "" unless url.present?

    uri = URI.parse(url)
    uri.scheme.in?(%w[http https]) ? url : ""
  rescue URI::InvalidURIError
    ""
  end

  def us_states
    [
      %w[AL Alabama], %w[AK Alaska], %w[AZ Arizona], %w[AR Arkansas],
      %w[CA California], %w[CO Colorado], %w[CT Connecticut], %w[DE Delaware],
      %w[FL Florida], %w[GA Georgia], %w[HI Hawaii], %w[ID Idaho],
      %w[IL Illinois], %w[IN Indiana], %w[IA Iowa], %w[KS Kansas],
      %w[KY Kentucky], %w[LA Louisiana], %w[ME Maine], %w[MD Maryland],
      %w[MA Massachusetts], %w[MI Michigan], %w[MN Minnesota], %w[MS Mississippi],
      %w[MO Missouri], %w[MT Montana], %w[NE Nebraska], %w[NV Nevada],
      %w[NH New\ Hampshire], %w[NJ New\ Jersey], %w[NM New\ Mexico],
      %w[NY New\ York], %w[NC North\ Carolina], %w[ND North\ Dakota],
      %w[OH Ohio], %w[OK Oklahoma], %w[OR Oregon], %w[PA Pennsylvania],
      %w[RI Rhode\ Island], %w[SC South\ Carolina], %w[SD South\ Dakota],
      %w[TN Tennessee], %w[TX Texas], %w[UT Utah], %w[VT Vermont],
      %w[VA Virginia], %w[WA Washington], %w[WV West\ Virginia],
      %w[WI Wisconsin], %w[WY Wyoming]
    ]
  end
end
