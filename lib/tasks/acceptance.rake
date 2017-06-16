unless Rails.env.production?
  desc 'Run acceptance tests (tests + rbp + rubocop)'
  task acceptance: %i[test rbp rubocop]
end
