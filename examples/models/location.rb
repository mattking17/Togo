class Location
  include DataMapper::Resource
  include Togo::DataMapper::Model
  property :id, Serial
  property :name, String
  property :pork, String
  property :midget, String
  property :fonk, String
  property :category_id, Integer
  belongs_to :category

  list_properties :fonk, :name, :midget
  form_properties :name, :pork, :midget, :fonk
end
