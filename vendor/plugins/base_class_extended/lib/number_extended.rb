class Numeric
  class NumberHelper 
    extend ActionView::Helpers::NumberHelper
    
    def self.options_for_number_to_currency(format)
      options = {}
      fmt = nil
      options[:unit] = format.sub(/#.*[#0]/i) { |s| fmt = s; '' }
      if fmt then
        separ = fmt =~ /[^#0]0+$/
        if separ then
          preci = fmt[separ+1..-1]
          options[:precision] = preci.size
          options[:separator] = fmt[separ,1]
          fmt = fmt[0,separ]
        else
          options[:precision] = 0
          options[:separator] = ''
        end
        delim = fmt =~ /[^0#][#0]{3}$/
        options[:delimiter] = delim ? fmt[delim, 1] : ''
      end
      options
    end
  
  end
  
  def currency(options_or_format={})
    options = if options_or_format.class <= String
      NumberHelper.options_for_number_to_currency(options_or_format)
    else
      options_or_format
    end
    NumberHelper.number_to_currency(self, options)
  end
  
  def human_size(percision=1)
    NumberHelper.number_to_human_size(self, percision)
  end
  
  def percentage(options={})
    NumberHelper.number_to_percentage(self, options)
  end
  
  def phone(options={})
    NumberHelper.number_to_phone(self, options)
  end
  
  def to_durations(low = :miliseconds, high = :weeks)
    res = [:miliseconds, :seconds, :minutes, :hours, :days, :weeks]
    return unless l = res.index(low)
    return unless h = res.index(high)
    return if l > h
    i = h
    t = self.to_f
    d = {}
    while i >= l do
      case res[i]
        when :miliseconds
          d[:miliseconds] = t * 1000
        when :seconds
          d[:seconds], t = t.divmod(1)
        when :minutes          
          d[:minutes], t = t.divmod(60)
        when :hours
          d[:hours], t = t.divmod(60 * 60)
        when :days
          d[:days], t = t.divmod(60 * 60 * 24)
        when :weeks
          d[:weeks], t = t.divmod(60 * 60 * 24 * 7)
      end
      i = i-1
    end
    d
  end
  
 
end
