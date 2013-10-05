# TODO: implement autoload from /app/strategies
ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/app/strategies"
Warden::Strategies.add(:dummy, DummyStrategy)