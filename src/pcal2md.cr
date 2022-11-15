require "option_parser"
require "string_scanner"

module Pcal2md
   VERSION = "0.9.2"

   class Event
      @text : String = ""
      @nr : Int32 = 0
      @hour : Int32 = 0
      @min : Int32 = 0
      @summary : String = ""

      def initialize(text : String, nr : Int32, ihour : Int32, imin : Int32, summ : String)
         @text    = text
         @nr      = nr
         @hour    = ihour
         @min     = imin
         @summary = summ
      end
   end
   
   class Day
      @d : Int32 = 0
      property events : Array(Event) = Array(Event).new
      
      def initialize(id : Int32)
         @d = id
      end
      
      def add_event(text : String, nr : Int32, ihour : Int32, imin : Int32, summ : String)
         puts "   Day.add_event #{text}"
         dy = Event.new(text, nr, ihour, imin, summ)
         @events << dy
      end

      def write_md(ofile : File, month : Month)
         puts "day"
         @events.each do |ev|
            puts "event #{ev.@text}"
            ofile.puts "* #{ev.@text}"
         end
         ofile.puts ""
      end

      def write_ics(ofile : File, year : Year, month : Month)
         puts "day"
         @events.each do |ev|
            puts "event #{ev.@nr}: #{ev.@text}"
            ofile.puts "BEGIN:VEVENT"
            ofile.puts "UID:rep#{ev.@nr}@cantifoone.be"
            ofile.puts "DTSTAMP:20220913T204300"
            ofile.puts "DTSTART:#{year.@y}%02d%02dT%02d%02d00" % [month.@m, @d, ev.@hour, ev.@min]
            ofile.puts "DURATION:PT2H"
            ofile.puts "SUMMARY:#{ev.@summary}"
            ofile.puts "LOCATION:Merem"
            ofile.puts "END:VEVENT"
         end
      end
   end

   class Month
      @m : Int32 = 0
      @days    = Hash(Int32, Day).new
      
      def initialize(im : Int32)
         @m = im
      end

      def to_s : String
         case @m
            when 1
               "Januari"
            when 2
               "Februari"
            when 3
               "Maart"
            when 4
               "April"
            when 5
               "Mei"
            when 6
               "Juni"
            when 7
               "Juli"
            when 8
               "Augustus"
            when 9
               "September"
            when 10
               "Oktober"
            when 11
               "November"
            when 12
               "December"
            else
               ""
         end
      end

      def add_event(iday : Int32, text : String, nr : Int32, ihour : Int32, imin : Int32, summ : String)
         puts "   Month.add_event Int #{iday}"
         
         da = @days[iday]?
         if da.nil?
            da = Day.new(iday)
            @days[iday] = da
         end
         da.add_event(text, nr, ihour, imin, summ)
      end

      def write_md(ofile : File, year : Year)
         puts "month"
         # first day of the month
         time1 = Time.local(year.y, @m, 1, 10, 20, 30, location: Time::Location.load("Europe/Brussels"))
         first = 1
         #ofile.puts "* time1 first #{first} #{time1.to_s}"
      
         # last day of the month
         go = true
         time2 : Time? = nil
         last = 31
         while go
            begin
               time2 = Time.local(year.y, @m, last, 10, 20, 30, location: Time::Location.load("Europe/Brussels"))
            rescue
               last -= 1
            end
            if !time2.nil?
               go = false
            end
         end
         #ofile.puts "* time2 last #{last} #{time2.not_nil!.to_s}"

         
         # day of week ma=1, di=2, ...
         dow1 = time1.day_of_week.value
         dow2 = time2.not_nil!.day_of_week.value
         #ofile.puts "* dow1 #{dow1} dow2 #{dow2}"
         
         # correction for start and end of month
         first  -= dow1-1
         last2   = last
         last2  += 7 - dow2
         #ofile.puts "* first #{first} last2 #{last2}"
         #ofile.puts
         
         # header of table
         ofile.puts "| Ma | Di | Wo | Do | Vr | Za | Zo |"
         ofile.puts "|----|----|----|----|----|----|----|"
         
         # build table body
         it = first
         wd = 0 # day of week counter
         s  = "|"
         while it <= last2
            if it >= 1 && it <= last
               s += "#{it} "
               
               da = @days[it]?
               if !da.nil?
                  da.events.each do |ev|
                     s += "<br/>#{ev.@text}"
                  end
               end
            else
               s += "   "
            end
            if wd < 6
               s += "|"
            end
            wd += 1
            if wd >= 7
               wd = 0
               ofile.puts s
               s = "|"
            end
            
            it += 1
         end

         #@days.each_key do |k|
         #   day = @days[k]
         #   ofile.puts "#### #{k}"
         #   day.write_md(ofile, self)
         #end
         ofile.puts ""
      end

      def write_ics(ofile : File, year : Year)
         puts "month --"

         @days.each_key do |k|
            puts "day"
            day = @days[k]
            day.write_ics(ofile, year, self)
         end
      end
   end
   
   class Year
      property y : Int32 = 0
      @months    = Hash(Int32, Month).new
      
      def initialize(iy : Int32)
         @y = iy
      end

      def add_event(imonth : Int32, iday : Int32, text : String, nr : Int32, ihour : Int32, imin : Int32, summ : String)
         puts "   Year.add_event Int #{iday}-#{imonth}"
         
         mn = @months[imonth]?
         if mn.nil?
            mn = Month.new(imonth)
            @months[imonth] = mn
         end
         mn.add_event(iday, text, nr, ihour, imin, summ)
      end

      def write_md(ofile : File)
          puts "year"
          @months.each_key do |k|
             month = @months[k]
             ofile.puts "### #{month.to_s} #{@y}"
             ofile.puts ""
             
             month.write_md(ofile, self)
          end
      end

      def write_ics(ofile : File)
          @months.each_key do |k|
             month = @months[k]
             puts "month"
             
             month.write_ics(ofile, self)
          end
      end
   end
   
   class Calendar
      def initialize
         @filename = ""
         @outname  = ""
         @fcontent = ""
         @years    = Hash(Int32, Year).new
         @ics = false
      end

      def get_options
         option_parser = OptionParser.parse do |parser|
            parser.banner = "Welcome to pcal2md!"
      
            parser.on "-v", "--version", "Show version" do
               puts "version #{VERSION}"
               exit
            end
            parser.on "-h", "--help", "Show help" do
               puts parser
               exit
            end
            parser.on "-i", "--ics", "Write .ics help" do
               puts "write ics"
               @ics = true
            end
            parser.on "-f NAME", "--file=NAME", "file name" do |fname|
               puts "fname #{fname}"
               @filename = fname
               if @filename == ""
                 puts "file name #{@filename}"
                 STDERR.puts "ERROR: file name is missing."
                 STDERR.puts parser
                 exit(1)
               end
            end
            parser.on "-o NAME", "--out=NAME", "out name" do |oname|
               puts "oname #{oname}"
               @outname = oname
               if @outname == ""
                 puts "out name #{@filename}"
                 STDERR.puts "ERROR: out file name is missing."
                 STDERR.puts parser
                 exit(1)
               end
            end
            parser.missing_option do |option_flag|
               STDERR.puts "ERROR: #{option_flag} is missing something."
               STDERR.puts ""
               STDERR.puts parser
               exit(1)
            end
            parser.invalid_option do |option_flag|
               STDERR.puts "ERROR: #{option_flag} is not a valid option."
              STDERR.puts parser
              exit(1)
            end
         end
      end

      def add_event(iyear : Int32, imonth : Int32, iday : Int32, text : String, nr : Int32, ihour : Int32, imin : Int32, summ : String)
         puts "   add_event Int #{iday}-#{imonth}-#{iyear}-#{nr}"
         
         yr = @years[iyear]?
         if yr.nil?
            yr = Year.new(iyear)
            @years[iyear] = yr
         end
         yr.add_event(imonth, iday, text, nr, ihour, imin, summ)
      end

      def parse_line(line : String, nr : Int32)
         puts "#{nr} : #{line}"
  
         s = StringScanner.new(line)
         puts "   eos #{s.eos?}"
         if !s.eos?
            puts "   non-empty line"
            if s.scan(/#/) == "#"
               puts "   comment line"
            else
               puts "   time line"

               day = s.scan(/\d\d/)
               if day.nil?
                  STDERR.puts "ERROR: 2 digits for day expected."
                  exit(1)
               end

               delim = s.scan(/\//)
               if delim.nil?
                  STDERR.puts "ERROR: delimiter / expected."
                  exit(1)
               end
               
               month = s.scan(/\d\d/)
               if month.nil?
                  STDERR.puts "ERROR: 2 digits for month expected."
                  exit(1)
               end

               delim = s.scan(/\//)
               if delim.nil?
                  STDERR.puts "ERROR: delimiter / expected."
                  exit(1)
               end
 
               year = s.scan(/\d\d\d\d/)
               if year.nil?
                  STDERR.puts "ERROR: 4 digits for year expected."
                  exit(1)
               end

               puts "   #{day}-#{month}-#{year}"
               s.scan(/\s/)
               text = s.scan(/.*/)
               if text.nil?  || text.empty?
                  STDERR.puts "ERROR: text for event expected."
                  exit(1)
               end

               puts "   #{text}"

               s2 = StringScanner.new(text)
               hour = s2.scan(/\d\d/)
               if hour.nil?
                  STDERR.puts "ERROR: 2 digits for hour expected."
                  exit(1)
               end

               s2.scan(/:/)
               min = s2.scan(/\d\d/)
               if min.nil?
                  STDERR.puts "ERROR: 2 digits for min expected."
                  exit(1)
               end

               s2.scan(/\s/)
               summ = s2.scan(/.*/)
               if summ.nil?  || summ.empty?
                  STDERR.puts "ERROR: summary for event expected."
                  exit(1)
               end

               puts "   hm #{hour}:#{min}--#{summ}"
               
               iday   = day.to_i
               imonth = month.to_i
               iyear  = year.to_i
               puts "   date as Int #{iday}-#{imonth}-#{iyear}"
               
               ihour = hour.to_i
               imin  = min.to_i
               puts "   time as Int #{ihour}-#{imin}"
               
               add_event(iyear, imonth, iday, text, nr, ihour, imin, summ)
            end
         else
            puts "   empty line"
         end
      end

      def read_file
         # read the list of events
         begin
            ffile = File.new(@filename)
            #@fcontent = ffile.gets_to_end
            nr = 1
            ffile.each_line do |line|
               parse_line(line, nr)
               nr = nr  + 1
            end
            ffile.close
         rescue e
            STDERR.puts "file not found #{e}"
            exit(1)
         end
      end

      def write_md2(ofile : File)
          @years.keys.sort.each do |k|
             #ofile.puts "## #{k}"
             #ofile.puts ""
             puts "year #{k}"
             year = @years[k]
             year.write_md(ofile)
          end
      end

      def write_md
         # write md to file
         begin
            File.open(@outname, "w") do |ofile|
               write_md2(ofile)
               ofile.close
            end
         rescue e
            STDERR.puts "out file not written #{e}"
            exit(1)
         end
      end

      def write_ics2(ofile : File)
          ofile.puts "BEGIN:VCALENDAR"
          ofile.puts "PRODID:-//cantifoone.be/NONSGML Cantifoone Calendar V1.0//EN"
          ofile.puts "VERSION:2.0"
          ofile.puts "METHOD:PUBLISH"
          ofile.puts "REFRESH-INTERVAL;VALUE=DURATION:PT15M"
          ofile.puts "X-PUBLISHED-TTL:PT15M"
          ofile.puts "BEGIN:VTIMEZONE"
          ofile.puts "TZID:/citadel.org/20211207_1/Europe/Brussels"
          ofile.puts "LAST-MODIFIED:20211207T194144Z"
          ofile.puts "X-LIC-LOCATION:Europe/Brussels"
          ofile.puts "BEGIN:DAYLIGHT"
          ofile.puts "TZNAME:CEST"
          ofile.puts "TZOFFSETFROM:+0100"
          ofile.puts "TZOFFSETTO:+0200"
          ofile.puts "DTSTART:19700329T020000"
          ofile.puts "RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU"
          ofile.puts "END:DAYLIGHT"
          ofile.puts "BEGIN:STANDARD"
          ofile.puts "TZNAME:CET"
          ofile.puts "TZOFFSETFROM:+0200"
          ofile.puts "TZOFFSETTO:+0100"
          ofile.puts "DTSTART:19701025T030000"
          ofile.puts "RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU"
          ofile.puts "END:STANDARD"
          ofile.puts "END:VTIMEZONE"
          
          @years.each_key do |k|
             puts "year #{k}"
             year = @years[k]
             year.write_ics(ofile)
          end
          ofile.puts "END:VCALENDAR"
      end

      def write_ics
         # write ics to file
         begin
            File.open(@outname, "w") do |ofile|
               write_ics2(ofile)
               ofile.close
            end
         rescue e
            STDERR.puts "out file not written #{e}"
            exit(1)
         end
      end

      def run
         puts "start2"
         get_options
         puts "get options ok"
         puts "file name #{@filename}"
         read_file
         if @ics
            write_ics
         else
            puts "write md"
            write_md
         end
      end
   end
   
   main = Calendar.new
   main.run
end

