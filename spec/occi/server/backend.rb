require "rspec"

module Occi
  module Server
    module Backend
      describe Occi::Server::Backend do
        describe "Register Infrastructure" do
          describe "Register Compute" do
            backends = Backend.register :backends => config[:backends]
            #TODO test if we get the right things
          end

          describe "Register Network" do

          end

          describe "Register Storage" do

          end
        end
      end
    end
  end
end