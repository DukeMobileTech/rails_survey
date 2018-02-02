object @display
cache @display

attributes :id, :position, :mode, :instrument_id, :title

child :instrument_questions do
  node :id do |iq|
    iq.id
  end

  node :identifier do |iq|
    iq.question.question_identifier if iq.question
  end

  node :type do |iq|
    iq.question.question_type if iq.question
  end

  node :number_in_instrument do |iq|
    iq.number_in_instrument
  end
end