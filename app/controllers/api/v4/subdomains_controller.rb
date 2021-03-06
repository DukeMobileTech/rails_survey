# frozen_string_literal: true

class Api::V4::SubdomainsController < Api::V4::ApiController
  respond_to :json
  before_action :set_domain, only: %i[create update destroy]
  before_action :set_subdomain, only: %i[update destroy]

  def create
    domain = @score_scheme.domains.find(params[:subdomain][:domain_id])
    subdomain = domain.subdomains.new(subdomain_params)
    if subdomain.save
      render json: subdomain, status: :created
    else
      render json: { errors: subdomain.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    respond_with @subdomain.update_attributes(subdomain_params)
  end

  def destroy
    respond_with @subdomain.destroy
  end

  private

  def subdomain_params
    params.require(:subdomain).permit(:title, :domain_id, :name)
  end

  def set_domain
    instrument = current_user.instruments.find(params[:instrument_id])
    @score_scheme = instrument.score_schemes.find(params[:score_scheme_id])
  end

  def set_subdomain
    @subdomain = @score_scheme.subdomains.find(params[:id])
  end
end
