module Api
  module V1
    module Frontend
      class QuestionsController < ApiApplicationController
        include ApiHelper
        respond_to :json

        def index
          @instrument = current_project.instruments.find(params[:instrument_id])
          @page_num = params[:page]
          @questions = if params[:all]
                         @instrument.questions
                       elsif !@page_num.blank? && params[:grid_id].blank?
                         @instrument.questions.where(grid_id: nil).includes(:options, :option_skips, :images, :question_randomized_factors).page(@page_num).per(20)
                       elsif !params[:grid_id].blank?
                         @instrument.questions.where(grid_id: params[:grid_id])
                       else
                         @instrument.questions.where(grid_id: nil)
                       end
        end

        def show
          @question = current_project.questions.find(params[:id])
        end

        def create
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.new(question_params)
          if question.save
            ReorderQuestionsWorker.perform_async(instrument.id, instrument.questions.last.number_in_instrument, question.number_in_instrument)
            render json: question, status: :created
          else
            render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.find(params[:id])
          old_number = question.number_in_instrument
          question.update_attributes(question_params)
          ReorderQuestionsWorker.perform_async(instrument.id, old_number, question.number_in_instrument) if old_number != question.number_in_instrument
          respond_with question
        end

        def destroy
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.find(params[:id])
          question_number = question.number_in_instrument
          if question.destroy
            DeleteQuestionWorker.perform_async(instrument.id, question_number)
            render nothing: true, status: :ok
          else
            render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def copy
          if params[:copy_to]
            instrument = Instrument.find(params[:copy_to])
            question = Question.find(params[:id])
            copy_question = question.dup
            copy_question.instrument_id = instrument.id
            copy_question.number_in_instrument = params[:q_position]
            copy_question.question_identifier = params[:q_id]
            if copy_question.save
              if question.images
                question.images.each do |img|
                  copy_image = Image.new
                  copy_image.photo = img.photo
                  copy_image.question_id = copy_question.id
                  copy_image.save
                end
              end
              create_instrument_translations(question, instrument) if question.translations
              render json: copy_question, status: :accepted
            end
          end
        end

        private

        def create_instrument_translations(question, instrument)
          question.translations.each do |translation|
            if instrument.translations
              existing_translation = instrument.translations.find_by_language(translation.language)
              instrument.translations.create(language: translation.language) unless existing_translation
            else
              instrument.translations.create(language: translation.language)
            end
          end
        end

        def question_params
          params.require(:question).permit(:text, :question_type, :question_identifier, :instrument_id, :reg_ex_validation, :child_update_count, :number_in_instrument, :reg_ex_validation_message, :identifies_survey, :grid_id, :instructions, :number_in_grid, :instrument_version_number, :critical)
        end
      end
    end
  end
end
