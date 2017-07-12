class SurveyExportWorker
  include Sidekiq::Worker

  def perform(survey_uuid, export_id)
    survey = get_survey(survey_uuid)
    survey.write_short_row(export_id)
    survey.write_long_row(export_id)
    survey.write_wide_row(export_id)
  end

  def get_survey(survey_uuid)
    key = Response.where(survey_uuid: survey_uuid).maximum('updated_at')
    Rails.cache.fetch("survey-#{survey_uuid}-#{key}", expires_in: 24.hours) do
      Survey.includes(:responses).where(uuid: survey_uuid).try(:first)
    end
  end
end
