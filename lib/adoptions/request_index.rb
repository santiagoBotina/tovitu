module Adoptions
  # Shared list query for the three AdoptionRequest index pages (shelter,
  # adopter, individual publisher). Eager-loads every association the row
  # rendering touches — adopter, shelter, and the pet's photo attachments +
  # blobs — so a row never triggers its own queries, and slices the relation to
  # a single page so lists stay cheap as requests accumulate.
  #
  # Fetches one extra record to detect a next page without a separate COUNT
  # query.
  class RequestIndex < ApplicationQuery
    DEFAULT_PAGE_SIZE = 20
    MAX_PER_PAGE = 100

    Result = Data.define(:records, :page, :per_page, :has_next)

    def initialize(scope:, params: {})
      @scope = scope
      @page = [ (params[:page] || 1).to_i, 1 ].max
      @per_page = (params[:per_page] || DEFAULT_PAGE_SIZE).to_i.clamp(1, MAX_PER_PAGE)
    end

    def call
      fetched = @scope
        .includes(:adopter, :shelter, pet: { photos_attachments: :blob })
        .limit(@per_page + 1)
        .offset((@page - 1) * @per_page)
        .to_a

      Result.new(
        records: fetched.first(@per_page),
        page: @page,
        per_page: @per_page,
        has_next: fetched.length > @per_page
      )
    end
  end
end
