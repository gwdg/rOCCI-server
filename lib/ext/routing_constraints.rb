module Ext
  class RoutingConstraints
    LEGACY_FORMATS = %i[text headers uri_list].freeze

    RULE_MAP = {
      legacy: %i[legacy_format?],
      non_legacy: %i[non_legacy_format?],
      action: %i[valid_action_term?],
      non_action: %i[non_action?],
      entity_ne_link: %i[entity_ne_link?]
    }.freeze

    attr_accessor :logger, :ruleset
    delegate :debug?, prefix: true, to: :logger

    def initialize(args = {})
      @logger = args.fetch(:logger)
      @ruleset = args.fetch(:ruleset)
    end

    def matches?(request)
      logger.debug "Matching #{request.uuid} against #{ruleset}" if logger_debug?
      ruleset.reduce(true) do |result, rule|
        rule_methods = RULE_MAP.fetch(rule)
        result && rule_methods.reduce(true) { |all, mtd| all && send(mtd, request) }
      end
    end

    class << self
      def build(ruleset)
        new logger: Rails.logger, ruleset: ruleset
      end
    end

    private

    def legacy_format?(request)
      LEGACY_FORMATS.include? request.format.symbol
    end

    def non_legacy_format?(request)
      !LEGACY_FORMATS.include?(request.format.symbol)
    end

    def valid_action_term?(request)
      request.query_parameters[:action] =~ /^[[:lower:]]([[:lower:]]|_)*$/
    end

    def non_action?(request)
      !request.query_parameters.key?(:action)
    end

    def entity_ne_link?(request)
      request.parameters[:entity] != 'link'
    end
  end
end
