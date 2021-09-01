# frozen_string_literal: true

module EasyExtensions
  module QueryString
    class Parser < Parslet::Parser
      rule(:space) { str(' ').repeat(1) }
      rule(:space?) { space.maybe }

      rule(:lparen) { str('(') >> space? }
      rule(:rparen) { str(')') >> space? }

      rule(:comma) { space? >> str(',') >> space? }

      rule(:and_operator) { (str('and') | str('AND')) >> space? }
      rule(:or_operator) { (str('or') | str('OR')) >> space? }

      rule(:field) { match['a-zA-Z0-9._'].repeat(1).as(:field) }

      rule(:simple_string) {
        match['a-zA-Z0-9._'].repeat(1).as(:string)
      }

      rule(:quoted_string) {
        str('"') >> (
        str('\\') >> any | str('"').absent? >> any
        ).repeat.as(:string) >> str('"')
      }

      rule(:string) {
        simple_string | quoted_string
      }

      rule(:array) {
        str('[') >> space? >>
            (value >> (comma >> value).repeat).maybe.as(:array) >>
            space? >> str(']')
      }

      rule(:value) {
        (string | array).as(:value)
      }

      rule(:one_value_filter) {
        (str('=') | str('~') | str('<=') | str('>=')
        ).as(:operator) >> space >> value
      }

      rule(:two_value_filter) {
        str('><').as(:operator) >> space? >>
            value.as(:value1) >>
            space? >> str('|') >> space? >>
            value.as(:value2)
      }

      rule(:filter) {
        space? >> (
        field >> space >>
            (one_value_filter | two_value_filter) >> space?
        ).as(:filter)
      }

      # The primary rule deals with parentheses
      rule(:primary) { lparen >> or_operation >> rparen | filter }

      # Note that following rules are both right-recursive
      rule(:and_operation) {
        (primary.as(:left) >>
            and_operator >>
            and_operation.as(:right)).as(:and) |
            primary }

      rule(:or_operation) {
        (and_operation.as(:left) >>
            or_operator >>
            or_operation.as(:right)).as(:or) |
            and_operation }

      # We start at the lowest precedence rule
      root(:or_operation)
    end

  end
end
