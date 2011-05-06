##############################################################################
#  Copyright 2011 Service Computing group, TU Dortmund
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##############################################################################

##############################################################################
# Description: Implementation specific Mixin to support reservation
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/core/Mixin'
require 'singleton'

module OCCI
  module Infrastructure
    class Reservation < OCCI::Core::Mixin

      include Singleton

      @@reservation = nil

      def initialize()
        term, scheme, title, attributes, actions, related, entities =  self.getMixin()
        super(term, scheme, title, attributes, actions, related, entities)
      end

      def getMixin()
        actions = []
        related = []
        entities = []

        term = "reservation"
        scheme = "http://schemas.ogf.org/occi/infrastructure/compute#"
        title = "Reservation"

        attributes = OCCI::Core::Attributes.new()
        attributes << OCCI::Core::Attribute.new(name = 'occi.reservation.start',        mutable = false, mandatory = true,  unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.reservation.leastype',     mutable = false, mandatory = false, unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.reservation.duration',     mutable = false, mandatory = true,  unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.reservation.preemptible',  mutable = false, mandatory = true,  unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.reservation.strategy',     mutable = false, mandatory = false, unique = true)

        return term, scheme, title, attributes, actions, related, entities
      end

      def self.get_scheme()
        scheme = %Q{"http://schemas.ogf.org/occi/infrastructure/compute#"}
        return scheme
      end

      def self.get_term()
        term = "reservation"
        return term
      end

      def self.title()
        title = "Reservation"
        return title
      end
    end
  end
end