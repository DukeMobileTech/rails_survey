# frozen_string_literal: true

module Api
  module V2
    class OptionTranslationsController < Api::V2::ApiController
      respond_to :json

      def index
        project = current_device_user.projects.find(params[:project_id])
        instrument = project.instruments.find(params[:instrument_id])
        display = instrument.displays.find(params[:display_id])
        @option_translations = display.all_option_translations.where(language: params[:language])
      end
    end
  end
end
