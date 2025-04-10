module AfipBill
  class LineItem
    attr_reader :name, :quantity, :imp_unitario, :iva, :code, :discount_percentage1, :discount_percentage2, :base_price

    def initialize(name, quantity, imp_unitario, iva=21, code=nil, discount_percentage1=nil, discount_percentage2=nil, base_price=nil)
      @name = name
      @quantity = quantity
      @imp_unitario = imp_unitario
      @iva = iva
      @code = code
      @discount_percentage1 = discount_percentage1
      @discount_percentage2 = discount_percentage2
      @base_price = base_price
    end

    def imp_total_unitario
      quantity * imp_unitario
    end

    def imp_iva
      imp_total_unitario * iva / 100
    end

    def imp_total_unitario_con_iva
      imp_total_unitario + imp_iva
    end
  end
end
