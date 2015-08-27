# == Schema Information
#
# Table name: devices
#
#  id         :integer          not null, primary key
#  identifier :string(255)
#  created_at :datetime
#  updated_at :datetime
#  label      :string(255)
#

require "spec_helper"

describe Device do
  it { should respond_to(:surveys) }
  it { should respond_to(:danger_zone?) }
  it { should respond_to(:last_project_survey) }

  describe "danger zone" do
    before :each do
      @device = create(:device) 
      @survey = create(:survey)
      @project = create(:project)
      @device.stub(:last_project_survey).and_return(@survey)
      Settings.danger_zone_days = 3
    end

    it "should be in the danger zone if last survey is too old" do
      @survey.stub(:updated_at).and_return(4.days.ago)
      @device.danger_zone?(@project).should be_truthy
    end

    it "should not be in the danger zone if last survey is new" do
      @survey.stub(:updated_at).and_return(1.minute.ago)
      @device.danger_zone?(@project).should be_falsey
    end

    it "should have a variable danger zone days" do
      Settings.danger_zone_days = 1
      @survey.stub(:updated_at).and_return(2.days.ago)
      @device.danger_zone?(@project).should be_truthy
    end
  end

  it "should not allow duplicate identifiers" do
    device = create(:device) 
    dup_device = Device.new
    dup_device.identifier = device.identifier
    dup_device.should_not be_valid
  end
end
