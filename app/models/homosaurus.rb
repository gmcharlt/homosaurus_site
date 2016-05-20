class Homosaurus < ActiveFedora::Base

  has_and_belongs_to_many :broader, predicate: ::RDF::Vocab::SKOS.broader, class_name: "Homosaurus"
  has_and_belongs_to_many :narrower, predicate: ::RDF::Vocab::SKOS.narrower, class_name: "Homosaurus"
  has_and_belongs_to_many :related, predicate: ::RDF::Vocab::SKOS.related, class_name: "Homosaurus"



  property :prefLabel, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :altLabel, predicate: ::RDF::Vocab::SKOS.altLabel, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_sortable
  end

  property :issued, predicate: ::RDF::DC.issued, multiple: false do |index|
    index.as :stored_sortable
  end

  property :modified, predicate: ::RDF::DC.modified, multiple: false do |index|
    index.as :stored_sortable
  end

  property :exactMatch, predicate: ::RDF::Vocab::SKOS.exactMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :closeMatch, predicate: ::RDF::Vocab::SKOS.closeMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  def self.getLabel field
    case field
      when "identifier"
        "<a href='http://purl.org/dc/terms/identifier' target='blank' title='Definition of Identifier in the Dublin Core Terms Vocabulary'>Identifier</a>"
      when "prefLabel"
        "<a href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Preferred Label in the SKOS Vocabulary'>Preferred Label</a>"
      when "altLabel"
        "<a href='http://www.w3.org/2004/02/skos/core#altLabel' target='blank'  title='Definition of Alternative Label in the SKOS Vocabulary'>Alternative Label (Use For)</a>"
      when "description"
        "<a href='http://www.w3.org/2000/01/rdf-schema#comment' target='blank'  title='Definition of Comment in the RDF Schema Vocabulary'>Description</a>"
      when "issued"
        "<a href='http://purl.org/dc/terms/issued' target='blank'  title='Definition of Issued in the Dublin Core Terms Vocabulary'>Issued (Created)</a>"
      when "modified"
        "<a href='http://purl.org/dc/terms/modified' target='blank'  title='Definition Modified in the Dublin Core Terms Vocabulary'>Modified</a>"
      when "exactMatch"
        "<a href='http://www.w3.org/2004/02/skos/core#exactMatch' target='blank'  title='Definition of exactMatch in the SKOS Vocabulary'>External Exact Match</a>"
      when "closeMatch"
        "<a href='http://www.w3.org/2004/02/skos/core#closeMatch' target='blank'  title='Definition of Modified in the SKOS Vocabulary'>External Close Match</a>"
      when "related"
        "<a href='http://www.w3.org/2004/02/skos/core#related' target='blank'  title='Definition of Related in the SKOS Vocabulary'>Related Terms</a>"
      when "broader"
        "<a href='http://www.w3.org/2004/02/skos/core#broader' target='blank'  title='Definition of Broader in the SKOS Vocabulary'>Broader Terms</a>"
      when "narrower"
        "<a href='http://www.w3.org/2004/02/skos/core#narrower' target='blank'  title='Definition of Narrower in the SKOS Vocabulary'>Narrower Terms</a>"
      else
        field.humanize
    end
  end

  def show_fields
    attributes.keys - ["id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def terms
    #fields - [:issued, :modified]
    attributes.keys - ["issued", "modified", "identifier", "id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def required? key
    return true if ['prefLabel', 'identifier'].include? key
    return false
  end

=begin
  def self.multiple? field
    #FIXME
    return false if ['preferred_label', 'description'].include? field.to_s
    return true
  end
=end

  def to_solr(doc = {} )
    doc = super(doc)

    doc['dta_homosaurus_lcase_prefLabel_ssi'] = self.prefLabel.downcase
    doc['dta_homosaurus_lcase_altLabel_ssim'] = []
    self.altLabel.each do |alt|
      doc['dta_homosaurus_lcase_altLabel_ssim'] << alt
    end

    doc['dta_homosaurus_lcase_comment_tesi'] = self.description


    doc

  end

  def self.all_terms_full_graph
    all_terms = Homosaurus.find_with_conditions("*:*", rows: '10000', fl: 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim' )
    all_terms = all_terms.sort_by { |term| term["prefLabel_tesim"].first }

    graph = ::RDF::Graph.new

    all_terms.each do |current_term|
      base_uri = ::RDF::URI.new("http://homosaurus.org/terms/#{current_term['identifier_ssi']}")
      graph << ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{current_term['identifier_ssi']}"]
      graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{current_term['prefLabel_tesim'].first}"]
      if current_term['altLabel_tesim'].present?
        current_term['altLabel_tesim'].each do |alt|
          graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
        end
      end

      graph << [base_uri, ::RDF::RDFS.comment, "#{current_term['description_tesim']}"] if current_term['description_tesim'].present?
      graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{current_term['issued_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]
      graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{current_term['modified_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]

      if current_term['broader_ssim'].present?
        current_term['broader_ssim'].each do |current_broader|
          graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/terms/#{current_broader.split('/').last}")] if current_broader.present?
        end
      end

      if current_term['narrower_ssim'].present?
        current_term['narrower_ssim'].each do |current_narrower|
          graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/terms/#{current_narrower.split('/').last}")] if current_narrower.present?
        end
      end

      if current_term['related_ssim'].present?
        current_term['related_ssim'].each do |current_related|
          graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/terms/#{current_related.split('/').last}")] if current_related.present?
        end
      end

      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{current_term['exactMatch_tesim']}")] if current_term['exactMatch_tesim'].present?
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{current_term['closeMatch_tesim']}")] if current_term['closeMatch_tesim'].present?

    end
    graph


  end

  def full_graph
    base_uri = ::RDF::URI.new("http://homosaurus.org/terms/#{self.identifier}")
    graph = ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.prefLabel}"]
    self.altLabel.each do |alt|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
    end
    graph << [base_uri, ::RDF::RDFS.comment, "#{self.description}"] if self.description.present?
    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::XSD.date)]

    self.broader.each do |current_broader|
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/terms/#{current_broader.id.split('/').last}")] if current_broader.present?
    end

    self.narrower.each do |current_narrower|
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/terms/#{current_narrower.id.split('/').last}")] if current_narrower.present?
    end

    self.related.each do |current_related|
      graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/terms/#{current_related.id.split('/').last}")] if current_related.present?
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{self.exactMatch}")] if self.exactMatch.present?
    graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{self.closeMatch}")] if self.closeMatch.present?
    graph
  end


end