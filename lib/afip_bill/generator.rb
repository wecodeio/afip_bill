require "json"
require "date"
require "afip_bill/check_digit"
require "barby/barcode/code_25_interleaved"
require "barby/outputter/html_outputter"
require "pdfkit"

module AfipBill
  class Generator
    attr_reader :afip_bill, :bill_name, :bill_type, :user, :line_items, :header_text
    
    HEADER_PATH = File.dirname(__FILE__) + '/views/shared/_factura_header.html.erb'.freeze
    FOOTER_PATH = File.dirname(__FILE__) + '/views/shared/_factura_footer.html.erb'.freeze
    BRAVO_CBTE_TIPO = {
      '01' => { directory: 'bills', template: 'factura_a', doc_name: 'factura', doc_type: 'a' },
      '06' => { directory: 'bills', template: 'factura_b', doc_name: 'factura', doc_type: 'b' },
      '03' => { directory: 'notes', template: 'nota_a', doc_name: 'Nota de crédito', doc_type: 'a' },
      '08' => { directory: 'notes', template: 'nota_b', doc_name: 'Nota de crédito', doc_type: 'b' },
      '02' => { directory: 'notes', template: 'nota_a', doc_name: 'Nota de débito', doc_type: 'a' },
      '07' => { directory: 'notes', template: 'nota_b', doc_name: 'Nota de débito', doc_type: 'b' },
    }.freeze
    IVA = 21.freeze

    def initialize(bill, user, line_items = [], header_text = 'ORIGINAL')
      @afip_bill = JSON.parse(bill)
      @user = user
      @bill_name = bill_name_s
      @bill_type = bill_type_s
      @line_items = line_items
      @template_header = ERB.new(File.read(HEADER_PATH)).result(binding)
      @template_footer = ERB.new(File.read(FOOTER_PATH)).result(binding)
      @header_text = header_text
    end

    def bill_name_s
      BRAVO_CBTE_TIPO[afip_bill["cbte_tipo"]][:doc_name].capitalize
    end

    def bill_type_s
      BRAVO_CBTE_TIPO[afip_bill["cbte_tipo"]][:doc_type]
    end

    def barcode
      @barcode ||= Barby::Code25Interleaved.new(code_numbers)
    end

    def pdfkit_options
      {
        zoom: '1.65', 
        'margin-bottom': '0.05in', 
        'margin-top': '0.05in', 
        'margin-left': '0.2in', 
        'margin-right': '0.2in'
      }
    end

    def generate_pdf_file
      tempfile = Tempfile.new("afip_bill.pdf")
      PDFKit.new(template, pdfkit_options).to_file(tempfile.path)
    end

    def generate_pdf_string
      PDFKit.new(template, pdfkit_options).to_pdf
    end

    private

    def bill_path
      File.dirname(__FILE__) + "/views/#{template_directory}/#{template_name}.html.erb"
    end

    def template_name
      BRAVO_CBTE_TIPO[afip_bill["cbte_tipo"]][:template]
    end

    def template_directory
      BRAVO_CBTE_TIPO[afip_bill["cbte_tipo"]][:directory]
    end

    def code_numbers
      code = code_hash.values.join("")
      last_digit = CheckDigit.new(code).calculate
      result = "#{code}#{last_digit}"
      result.size.odd? ? "0" + result : result
    end

    def code_hash
      {
        cuit: afip_bill["doc_num"].tr("-", "").strip,
        cbte_tipo: afip_bill["cbte_tipo"],
        pto_venta: AfipBill.configuration[:sale_point],
        cae: afip_bill["cae"],
        vto_cae: afip_bill["fch_vto_pago"]
      }
    end

    def template
      ERB.new(File.read(bill_path)).result(binding)
    end
  end
end
