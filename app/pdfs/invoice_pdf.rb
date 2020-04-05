class InvoicePdf < Prawn::Document

  require "open-uri"

  def initialize(invoice, view)
    super(top_margin: 70)
    @invoice = invoice
    @view = view 
    logo
    invoice_number
    line_items unless @invoice["lines"]["data"][0]["plan"].blank?
    total_price
  end

  def logo
    image open("https://s3-us-west-2.amazonaws.com/tiphiveupload/assets/Friyay_wide_145.png")
  end

  def invoice_number
    text "Friyay Stripe Invoice", size: 16, style: :bold
    text "Stripe Ref : #{@invoice["id"]}", size: 16, style: :normal
  end
  
  def line_items
    move_down 20
    table line_item_rows do
      row(0).font_style = :bold
      columns(1..3).align = :right
      self.row_colors = ["DDDDDD", "FFFFFF"]
      self.header = true
    end
  end

  def line_item_rows
    [["Monthly plan/Yearly plan", "Price", "Total users", "Total"]] +
    @invoice["lines"].map { |line| [line["plan"]["name"], price(line["plan"]["amount"]), line["quantity"], price(line["amount"])] }
  end
  
  def price(num)
    @view.number_to_currency((num.to_i/100.0))
  end
  
  def total_price
    move_down 15
    text "Total Price: #{price(@invoice["total"])}", size: 16, style: :bold
  end

end