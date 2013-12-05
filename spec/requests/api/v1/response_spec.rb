require 'spec_helper'

describe "Responses API" do
  before :each do
    @question = FactoryGirl.create(:question)
    @survey = FactoryGirl.create(:survey)
    @response = FactoryGirl.build(:response)
  end

  it 'returns a successful response if response is valid' do
    post '/api/v1/responses',
      response:
        {
          'question_id' => @question.id,
          'survey_uuid' => @survey.uuid
        }
    expect(response).to be_success
  end

  it 'returns an unsuccessful response if missing question id' do
    post '/api/v1/responses',
      response:
        {
          'survey_uuid' => @survey.uuid
        }
    expect(response).to_not be_success
  end

  it 'returns an unsuccessful response if missing survey uuid' do
    post '/api/v1/responses',
      response:
        {
          'question_id' => @question.id
        }
    expect(response).to_not be_success
  end

  it 'returns an unsuccessful response if invalid survey uuid' do
    post '/api/v1/responses',
      response:
        {
          'question_id' => @question.id,
          'survey_uuid' => '-1'
        }
    expect(response).to_not be_success
  end

  it 'returns an unsuccessful response if invalid question id' do
    post '/api/v1/responses',
      response:
        {
          'question_id' => '-1',
          'survey_uuid' => @survey.uuid 
        }
    expect(response).to_not be_success
  end

  it 'should not respond to a get request' do
    lambda { get '/api/v1/responses' }.should raise_error
  end
end