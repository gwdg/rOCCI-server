class Mixin
  include MongoMapper::Document

  key :term,      String
  key :scheme,    String
  key :title,     String
  key :resources, Set
  key :owner,     String

  timestamps!
end