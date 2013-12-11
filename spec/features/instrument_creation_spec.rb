require "spec_helper"

feature "Instrument Creation", js: true do
  before :each do
    @user = FactoryGirl.create(:user)
    visit '/users/sign_in'
    fill_in 'user_email', :with => @user.email
    fill_in 'user_password', :with => @user.password
    click_button 'Sign in'
    visit "/instruments/new"
  end

  scenario "user adds a new question" do
    click_link "Add Question"
    expect(page).to have_text("Question type")
  end

  scenario "user removes a question" do
    click_link "Add Question"
    click_link "Remove Question"
    expect(page).to_not have_text("Question type")
  end

  scenario "user adds an option" do
    click_link "Add Question"
    click_link "Add Option"
    expect(page).to have_text("Next question")
  end

  scenario "user deletes an option" do
    click_link "Add Question"
    click_link "Add Option"
    click_link "Remove Option"
    expect(page).to_not have_text("Next question")
  end

  scenario "user saves an instrument" do
    fill_in 'instrument_title', :with => "Test Instrument"
    click_button "Create Instrument"
    expect(page).to have_text("Successfully created instrument.")
    expect(page).to have_text("Test Instrument")
  end

  scenario "user saves an instrument with a question" do
    fill_in 'instrument_title', :with => "Test Instrument"
    click_link "Add Question"
    first(:css, "input[id$='question_identifier']").set("qid")
    find(:css, "textarea[id$='text']").set("Question text")
    click_button "Create Instrument"
    expect(page).to have_text("Successfully created instrument.")
    expect(page).to have_text("Question text")
    expect(page).to have_text("Test Instrument")
  end
end
