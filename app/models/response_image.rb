# frozen_string_literal: true

# == Schema Information
#
# Table name: response_images
#
#  id            :integer          not null, primary key
#  response_uuid :string
#  created_at    :datetime
#  updated_at    :datetime
#

class ResponseImage < ApplicationRecord
  has_one_attached :picture
  belongs_to :response, foreign_key: :response_uuid, primary_key: :uuid
  delegate :project, to: :response
  validates :response_uuid, presence: true
  validates :picture, attached: true, content_type: ['image/png', 'image/jpg', 'image/jpeg']

  def picture_data=(data_value)
    StringIO.open(Base64.decode64(data_value)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = "created_at_#{DateTime.now.to_i}.jpeg"
      data.content_type = 'image/jpeg'
      self.picture = data
    end
  end

  def as_json(options = {})
    super((options || {}).merge(methods: [:picture_url]))
  end

  def picture_url
    picture.url(:small)
  end

  def self.to_zip(name, zipped_file, pictures_export_id)
    zipped_file = File.open(zipped_file, 'a+')
    Zip::OutputStream.open(zipped_file.path) do |zipfile|
      all.each do |response_image|
        next unless response_image.picture.exists?

        title = "#{response_image.versioned_question(response_image.response.question_identifier).try(:question_identifier)}-#{response_image.response.id}-#{response_image.picture_file_name}"
        zipfile.put_next_entry("#{name}/#{title}")
        photos_root = File.join('files').to_s
        photo_path = response_image.picture.url.split('?')
        photo_path = photo_path[0]
        path_arr = photo_path.split('/')
        path_arr.insert(3, 'original')
        photo_abs_url = photos_root + path_arr.join('/')
        photo_data = open(photo_abs_url)
        zipfile.print IO.read(photo_data)
      end
    end
    zipped_file.close
    pictures_export = ResponseImagesExport.find(pictures_export_id)
    pictures_export.update(done: true)
  end

  def versioned_question(qid)
    response.survey.instrument_version.find_question_by(question_identifier: qid)
  end
end
