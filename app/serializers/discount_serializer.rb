class DiscountSerializer < Panko::Serializer
  attributes :id, :percentage, :explanation, :start_date, :end_date, :resolution_description, :administrative_type
end
