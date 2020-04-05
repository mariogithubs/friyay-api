module V2
  class ContactInformationController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!

    def create
      contact_information = ContactInformation.new(contact_information_params)
      contact_information.domain = current_domain
      contact_information.save
      
      render_errors(contact_information.errors.full_messages) && return if contact_information.errors.any?
      render json: contact_information, status: :created, location: [:v2, contact_information]
    end

    def show
      domain = Domain.find_by_id(params[:id])
      contact_information = domain.contact_information
      render json: contact_information, status: :ok, location: [:v2, contact_information]
    end

    def update
      contact_information = ContactInformation.find(params[:id])
      contact_information.update_attributes(contact_information_params)

      render json: contact_information, status: :ok, location: [:v2, contact_information]
    end

    def countries
      countries = CS.countries
      render json: countries, status: :ok
    end

    def states
      states = CS.states(params[:country])
      render json: states, status: :ok
    end

    private
    def contact_information_params
      params.require(:data).require(:attributes).permit(:first_name, :last_name, :company_name, :address, :appartment, :city, :country, :state, :zip)
    end

  end
end
