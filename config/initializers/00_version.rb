# Log versions
Rails.logger.info "Starting rOCCI-server/#{ROCCIServer::VERSION} with rOCCI-core/#{::Occi::Core::VERSION} " \
                  "running on Ruby/#{RUBY_VERSION} in PUMA/#{::Puma::Const::VERSION}"
