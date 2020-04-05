module V2
  class AttachmentsController < ApplicationController
    before_action :authenticate_user!

    def index
      # support getting any user attachment by IDs
      if params[:ids].present?
        attachments = current_user.attachments.where(id: params[:ids])
      else
        tip = current_user.tips.find_by(id: params[:tip_id])
        attachments = tip.attachments
      end
      attachments = attachments.where('attachable_id IS NULL') if (params[:filter] == 'null-attachable')

      render json: AttachmentSerializer.new(attachments)
    end

    def show
      attachment = current_user.attachments.find_by(id: params[:id])
      render_errors('Could not find attachment') && return if attachment.nil?

      render json: AttachmentSerializer.new(attachment)
    end

    def create
      if attachment_params[:file].present?
        params[:data][:attributes][:type] = Attachment.detect_attachment_type(attachment_params[:file].content_type)
      end

      if attachment_params[:remote_file_url].present?
        params[:data][:attributes][:type] = Attachment.detect_attachment_type(attachment_params[:mime_type])
      end

      attachment = init_new_attachment or return
      attachment.save!

      render_errors(attachment.errors.full_messages) && return if attachment.errors.any?

      if @tip && params[:response_with_tip].present?
        render json: @tip, status: :ok, location: v2_attachment_url(@tip)
      else
        render json: AttachmentSerializer.new(attachment), status: :created, location: v2_attachment_url(attachment)
      end
    end

    def destroy
      # this commented code- only workspace admin and attachment creator can delete the attachment
      # attachment = current_user.has_role?('admin', current_domain) ? Attachment : current_user.attachments
      attachment = Attachment.find(params[:id])

      render_errors('Could not find attachment') && return if attachment.blank?

      attachment.destroy

      render json: {}, status: :no_content
    end

    private

    def init_new_attachment
      if params[:tip_id].present?
        # this commented code- only workspace admin and tip's creator can add the attachment
        # @tip = current_user.has_role?('admin', current_domain) ? Tip : current_user.tips
        # @tip = @tip.find_by(id: params[:tip_id].to_i)
        @tip = Tip.find_by(id: params[:tip_id])
        render_errors('Could not find tip') && return if @tip.nil?
        attachment = @tip.attachments.new(attachment_params)
      else
        # attachment = current_user.has_role?('admin', current_domain) ? Attachment : current_user.attachments
        attachment = Attachment.new(attachment_params)
      end

      attachment.user_id = current_user.id

      attachment
    end

    def attachment_params
      params.require(:data).require(:attributes).permit(:type, :file, :remote_file_url, :mime_type, :relationships)
    end
  end
end
