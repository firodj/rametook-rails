class Time
#  %a - The abbreviated weekday name (``Sun'')
#  %A - The  full  weekday  name (``Sunday'')
#  %b - The abbreviated month name (``Jan'')
#  %B - The  full  month  name (``January'')
#  %c - The preferred local date and time representation
#  %d - Day of the month (01..31)
#  %H - Hour of the day, 24-hour clock (00..23)
#  %I - Hour of the day, 12-hour clock (01..12)
#  %j - Day of the year (001..366)
#  %m - Month of the year (01..12)
#  %M - Minute of the hour (00..59)
#  %p - Meridian indicator (``AM''  or  ``PM'')
#  %S - Second of the minute (00..60)
#  %U - Week  number  of the current year,
#          starting with the first Sunday as the first
#          day of the first week (00..53)
#  %W - Week  number  of the current year,
#          starting with the first Monday as the first
#          day of the first week (00..53)
#  %w - Day of the week (Sunday is 0, 0..6)
#  %x - Preferred representation for the date alone, no time
#  %X - Preferred representation for the time alone, no date
#  %y - Year without a century (00..99)
#  %Y - Year with century
#  %Z - Time zone name
#  %% - Literal ``%'' character
  def strfindo(format)
    strftime(format.gsub(/%[\w%]/im) { |match|
      case match
        when '%a'
          self.respond_to?(:hr) ? self.hr : match
        when '%A'
          self.respond_to?(:hari) ? self.hari : match
        when '%b'
          self.respond_to?(:bln) ? self.bln : match
        when '%B'
          self.respond_to?(:bulan) ? self.bulan : match
        when '%x'
          '%d/%m/%Y'
        when '%Z'
          tz = strftime(match)
          Hash.new(tz).update({'WIT'=>'WIB','CIT'=>'WITA','EIT'=>'WIT'})[tz]
        else
          match
      end
    })
  end
  
  def self.strfindo_formats
    {:default => "%d/%m/%Y, %H:%M", :same_year => "%d %b, %H:%M", :same_month => "%a %d %b, %H:%M", :same_day => "%H:%M"}
  end
  
  def strfindo_by_today(formats = Time.strfindo_formats)
    today = Time.now
    format = formats[:default] || "%Y-%m-%d"
    if today.year == self.year then
      format = formats[:same_year] if formats[:same_year]
      if today.month == self.month then
        format = formats[:same_month] if formats[:same_month]
        if today.day == self.day then
          format = formats[:same_day] if formats[:same_day]
        end
      end
    end

    strfindo(format)
  end
  
  # :formats => strfindo_formats
  # :second, :minute, :hour, :ago, :left
  def self.strfindo_range(range, options = {})
    today = Time.now
    diff  = self - today
    if diff > range then
      
    else 
    
    end
    
  end
  
  
end

class Date
  # different from time
  def diff(time)
    if self > time
      t2, t1 = self, time
    else
      t2, t1 = time, self
    end
    
    y, m, d = [t2.year - t1.year, t2.month - t1.month, t2.day - t1.day]
    if m < 0 then 
      y = y - 1 
      m = (12 - t1.month) + t2.month
    end
    if d < 0 then
      m = m - 1
      x = self > time ? (t1 >> 1) - t1.day : x = t2 - t2.day
      d = (x.day - t1.day) + t2.day
    end
    
    [y, m, d]
  end
end
