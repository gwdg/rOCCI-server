unless Rails.env.production?
  require 'rubocop/rake_task'

  desc 'Execute rubocop -DR'
  RuboCop::RakeTask.new(:rubocop) do |tsk|
    tsk.options = ['-DR'] # rails + display cop name
  end
end
