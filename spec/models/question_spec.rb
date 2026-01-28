# == Schema Information
#
# Table name: questions
#
#  id                    :integer          not null, primary key
#  text                  :text
#  question_type         :string
#  question_identifier   :string
#  created_at            :datetime
#  updated_at            :datetime
#  deleted_at            :datetime
#  identifies_survey     :boolean          default(FALSE)
#  question_set_id       :integer
#  option_set_id         :integer
#  instruction_id        :integer
#  special_option_set_id :integer
#  parent_identifier     :string
#  folder_id             :integer
#  validation_id         :integer
#  rank_responses        :boolean          default(FALSE)
#  versions_count        :integer          default(0)
#  images_count          :integer          default(0)
#

require "spec_helper"

describe Question do
  it { should respond_to(:options) }
  it { should respond_to(:instrument) }
  
  before :each do
    @question = create(:question)
  end

  describe "translations" do
    before :each do
      @translation = create(:question_translation)
    end

    it "should have a translation" do
      @translation.question.translation_for(@translation.language).should be_truthy
    end

    it "should have a translation" do
      @translation.question.translation_for('nope').should be_falsey
    end

    it "should return the correct translation" do
      @translation.question.translated_for(@translation.language, :text).should == @translation.text
    end
  end

  describe "options" do
    before :each do
      @option = create(:option)
    end
    
    it "should respond true to has_options if has options" do
      @option.question.options?.should be_truthy
    end

    it "should respond false to has_options if no options" do
      @question.options?.should be_falsey
    end
  end

  describe "validations" do
    it "should require a question identifier" do
      @question.question_identifier = nil
      @question.should_not be_valid
    end

    it "should not allow a blank question identifier" do
      @question.question_identifier = ' ' 
      @question.should_not be_valid
    end

    it "should not allow blank text" do
      @question.text = ' ' 
      @question.should_not be_valid
    end

    it "should require a sequence number in the instrument" do
      @question.number_in_instrument = nil
      @question.should_not be_valid
    end
  end

  it "should update the instrument version on update", versioning: true do
    old_count = @question.instrument.versions.count
    @question.update_attributes!(text: 'New text')
    new_count = @question.instrument.versions.count
    new_count.should == old_count + 1
  end
end
