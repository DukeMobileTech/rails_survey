# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  authentication_token   :string
#  created_at             :datetime
#  updated_at             :datetime
#  failed_attempts        :integer          default(0)
#  unlock_token           :string
#  locked_at              :datetime
#  gauth_secret           :string
#  gauth_enabled          :string           default("f")
#  gauth_tmp              :string
#  gauth_tmp_datetime     :datetime
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string
#  invitations_count      :integer          default(0)
#

class User < ActiveRecord::Base
  attr_accessor :gauth_token
  include ComplexPassword
  devise :invitable, :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :timeoutable, :lockable # :google_authenticatable
  before_save :ensure_authentication_token
  after_create :set_default_role
  has_many :user_projects
  has_many :projects, through: :user_projects
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  def set_default_role
    role = Role.find_by_name('user')
    return unless role
    UserRole.create(user_id: id, role_id: role.id)
  end

  def ensure_authentication_token
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  def user?
    roles.find_by_name('user')
  end

  def admin?
    roles.find_by_name('admin')
  end

  def super_admin?
    roles.find_by_name('super_admin')
  end

  def manager?
    roles.find_by_name('manager')
  end

  def analyst?
    roles.find_by_name('analyst')
  end

  def translator?
    roles.find_by_name('translator')
  end

  def wiki_editor?
    roles.find_by_name('wiki_editor')
  end

  def admin_user?
    admin? || super_admin?
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
