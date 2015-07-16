class InstrumentsController < ApplicationController
  after_action :verify_authorized
  
  def index
    @instruments = current_project.instruments
    authorize @instruments
  end

  def show
    @project = current_project
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
  end

  def new
    @project = current_project
    @instrument = current_project.instruments.new
    authorize @instrument
  end

  def create
    @instrument = current_project.instruments.new(params[:instrument])
    authorize @instrument
    if @instrument.save
      redirect_to project_instrument_path(current_project, @instrument), notice: "Successfully created instrument."
    else
      render :new
    end
  end

  def edit
    @project = current_project
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
  end

  def update
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    if @instrument.update_attributes(params[:instrument])
      redirect_to project_instrument_path(current_project, @instrument), notice: "Successfully updated instrument."
    else
      render :edit
    end
  end

  def destroy
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    @instrument.destroy
    redirect_to project_instruments_url, notice: "Successfully destroyed instrument."
  end

  def csv_export
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    respond_to do |format|
      format.csv do 
        send_data @instrument.to_csv, 
          type: 'text/csv; charset=iso-8859-1; header=present',
          disposition: "attachment; filename=#{@instrument.title}_#{@instrument.current_version_number}.csv"
      end
    end
  end

  def pdf_export
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    respond_to do |format|
      format.pdf do
        pdf = InstrumentPdf.new(@instrument)
        send_data pdf.render, filename: pdf.display_name, type: 'application/pdf'
      end
    end
  end

  def export_responses
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    root = File.join('files', 'exports').to_s
    long_csv_file = File.new(root + "/#{Time.now.to_i}" + "_long" + ".csv", "a+")
    long_csv_file.close
    wide_csv_file = File.new(root + "/#{Time.now.to_i}" + "_wide" + ".csv", "a+")
    wide_csv_file.close
    short_csv_file = File.new(root + "/#{Time.now.to_i}" + "_short" + ".csv", "a+")
    short_csv_file.close
    export = ResponseExport.create(:instrument_id => @instrument.id, :long_format_url => long_csv_file.path, 
      :wide_format_url => wide_csv_file.path, :short_format_url => short_csv_file.path, :instrument_versions => @instrument.survey_instrument_versions)
    long_id = InstrumentLongResponsesExportWorker.perform_async(@instrument.id, long_csv_file.path)
    wide_id = InstrumentWideResponsesExportWorker.perform_async(@instrument.id, wide_csv_file.path)
    short_id = InstrumentShortResponsesExportWorker.perform_async(@instrument.id, short_csv_file.path)
    StatusWorker.perform_in(1.minute, export.id, long_id, 'long_job')
    StatusWorker.perform_in(1.minute, export.id, wide_id, 'wide_job')
    StatusWorker.perform_in(1.minute, export.id, short_id, 'short_job')
    unless @instrument.response_images.empty?
      zipped_file = File.new(root + "/#{Time.now.to_i}.zip", 'a+')
      zipped_file.close 
      pictures_export = ResponseImagesExport.create(:response_export_id => export.id, :download_url => zipped_file.path)
      InstrumentImagesExportWorker.perform_async(@instrument.id, zipped_file.path, pictures_export.id)
    end
    redirect_to project_response_exports_path(current_project)
  end
  
  def move
    @projects = current_user.projects
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
  end
  
  def update_move
    @instrument = current_project.instruments.find(params[:id])
    authorize @instrument
    @project = current_user.projects.find(params[:project_id])
    if @instrument.update_attributes(:project_id => params[:end_project])
      redirect_to project_path(@project)
    end
  end
  
end
