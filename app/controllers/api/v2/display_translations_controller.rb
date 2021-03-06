# frozen_string_literal: true

module Api
  module V2
    class DisplayTranslationsController < Api::V2::ApiController
      respond_to :json

      def index
        project = current_device_user.projects.find(params[:project_id])
        instrument = project.instruments.find(params[:instrument_id])
        @display_translations = instrument.display_translations.where(language: params[:language])
      end
    end
  end
end
