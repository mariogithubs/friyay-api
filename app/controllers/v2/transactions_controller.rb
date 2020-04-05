module V2
  class TransactionsController < ApplicationController

    def index
      begin
        paid_invoices = Stripe::Invoice.list(customer: params[:stripe_customer_id])
        upcoming_invoices = Stripe::Invoice.upcoming(customer: params[:stripe_customer_id])
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message) && return if e.message
      end
  
      render json: { invoices: { paid_invoices: paid_invoices, upcoming_invoice: upcoming_invoices } }
    end

    def show
      begin
        invoice = Stripe::Invoice.retrieve(params[:id])
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message) && return if e.message
      end
        
      render json: invoice
    end

    def pdf
      begin
        invoice = Stripe::Invoice.retrieve(params[:id])
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message) && return if e.message
      end
        
      pdf = InvoicePdf.new(invoice, view_context)
      send_data pdf.render, filename: 'invoice.pdf'
    end

  end  
end
