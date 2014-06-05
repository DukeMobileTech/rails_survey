module Api
  module V1
    module Frontend
      class QuestionsController < ApiApplicationController
        respond_to :json
        
        def index
          instrument = current_project.instruments.find(params[:instrument_id])
          questions = instrument.questions.page(params[:page]).per(Settings.questions_per_page)
          authorize questions
          respond_with questions, include: :translations
        end

        def show
          question = Question.find(params[:id])
          authorize question
          respond_with question
        end

        def create
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.new(params[:question])
          authorize question
          if question.save
            instrument.reorder_questions(instrument.questions.last.number_in_instrument, question.number_in_instrument)
            render json: question, status: :created
          else
            render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.find(params[:id])
          authorize question
          old_number = question.number_in_instrument
          question.update_attributes(params[:question])
          instrument.reorder_questions(old_number, question.number_in_instrument) if old_number != question.number_in_instrument
          respond_with question 
        end

        def destroy
          instrument = current_project.instruments.find(params[:instrument_id])
          question = instrument.questions.find(params[:id])
          authorize question
          question_number = question.number_in_instrument
          if question.destroy
            instrument.reorder_questions_after_delete(question_number)
            render nothing: true, status: :ok
          else
            render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
