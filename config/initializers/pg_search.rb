PgSearch.multisearch_options = {
  using: {
    tsearch: { dictionary: "korean", tsvector_column: "tsvector_content_tsearch" }
  }
}
