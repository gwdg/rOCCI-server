unless Rails.env.production?
  require 'rails_best_practices'

  desc 'Execute rails_best_practices'
  task rbp: :environment do
    analyzer = RailsBestPractices::Analyzer.new('.')
    analyzer.analyze
    puts analyzer.output
  end
end
