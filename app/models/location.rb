class Location < ApplicationRecord
	include Searchable
	def self.search(query, filters)
     # a lambda function adds conditions to a search definition
     set_filters = lambda do |context_type, filter|
       @search_definition[:query][:bool][context_type] |= [filter]
     end

     @search_definition = {
       # we indicate that there should be no more than 5 documents to return
       size: 5,
       # we define an empty query with the ability to
       # dynamically change the definition
       # Query DSL https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
       query: {
         bool: {
           must: [],
           should: [],
           filter: []
         }
       }
     }

     # match all documents
     if query.blank?
       set_filters.call(:must, match_all: {})
     else
       set_filters.call(
         :must,
         match: {
           name: {
             query: query,
             # fuzziness means you can make one typo and still match your document
             fuzziness: 1
           }
         }
       )
     end

     # the system will return only those documents that pass this filter
     if filters[:level].present?
       set_filters.call(:filter, term: { level: filters[:level] })
     end

     __elasticsearch__.search(@search_definition)
   end
end
