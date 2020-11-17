# == Schema Information
#
# Table name: response_exports
#
#  id                  :integer          not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#  instrument_id       :integer
#  instrument_versions :text
#  completion          :decimal(5, 2)    default(0.0)
#

class ResponseExport < ActiveRecord::Base
  serialize :instrument_versions
  belongs_to :instrument
  has_one :response_images_export, dependent: :destroy
  has_many :surveys, through: :instrument
  has_many :survey_exports, through: :surveys

  def compute_completion
    return if surveys.empty?

    remainder = survey_exports.where(last_response_at: nil).size

    percent = 100
    percent = (((surveys.size - remainder.to_f) / surveys.size) * 100).round if remainder > 0
    update_column(:completion, percent)
  end

  def download(format, extension)
    data = []
    survey_exports.each do |export|
      if format == 'wide'
        data << JSON.parse(export.wide) unless export.wide.nil?
      elsif format == 'long'
        JSON.parse(export.long).each { |arr| data << arr } unless export.long.nil?
      end
    end
    data = data.reject { |arr| arr.all?(&:blank?) }
    data = data.sort { |ar1, ar2| ar1[0].to_i <=> ar2[0].to_i }
    file = Tempfile.new("#{instrument_id}-#{id}-#{format}")
    if extension == 'csv'
      CSV.open(file, 'w') do |csv|
        csv << headers(format)
        if data
          data.each do |row|
            csv << row
          end
        else
          instrument.export_surveys if surveys.count > 0
        end
      end
    elsif extension == 'xlsx'
      Axlsx::Package.new do |p|
        wb = p.workbook
        wb.add_worksheet(name: instrument.title) do |sheet|
          sheet.add_row headers(format)
          data.each do |row|
            sheet.add_row row
          end
        end
        p.serialize(file.path)
      end
    end
    file
  end

  private

  def headers(format)
    if format == 'long'
      instrument.long_headers
    elsif format == 'wide'
      instrument.wide_headers
    end
  end
end
