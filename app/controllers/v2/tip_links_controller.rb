module V2
  class TipLinksController < ApplicationController
    before_action :authenticate_user!

    load_resource :tip, only: [:fetch]

    def show
      tip_link = current_user.tip_links.find(params[:id])
      render json: tip_link
    end

    def fetch
      render_errors('Url not provided.') && return unless tip_link_params[:url].present?

      render_errors('Url not valid.') && return unless uri?(format_tip_uri(tip_link_params[:url]))

      tip_link = current_user.tip_links.find_by(url: tip_link_params[:url])

      tip_link ||= current_user.tip_links.create(tip_id: @tip.id, url: format_tip_uri(tip_link_params[:url]))

      render_errors('Could not create tip link') && return if tip_link.errors.any?

      render json: tip_link, status: :created, location: [:v2, tip_link]
    end

    def destroy
      tip_link = current_user.tip_links.find(params[:id])
      tip_link.destroy
      render json: {}, status: :no_content
    end

    private

    def tip_link_params
      params.require(:data)
        .require(:attributes)
        .permit(
          :url
        )
    end

    def uri?(string)
      uri = URI.parse(string)
      %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      false
    rescue URI::InvalidURIError
      false
    end

    def format_tip_uri(uri)
      if uri !~ %r{(http|https)?:\/\/}
        uri.gsub!(%r{(http|https)?:(\/)?}, '')
        uri = 'http://' + uri
      end
      uri
    end
  end
end
