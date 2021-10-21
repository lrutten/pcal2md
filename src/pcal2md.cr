require "option_parser"
require "string_scanner"

module Pcal2md
   VERSION = "0.9.0"

   class Day
      @d : Int32 = 0
      property events : Array(String) = Array(String).new
      
      def initialize(id : Int32)
         @d = id
      end
      
      def add_event(text : String)
         puts "   Day.add_event #{text}"
         @events << text
      end

      def write_md(ofile : File, month : Month)
          @events.each do |txt|
             ofile.puts "* #{txt}"
          end
          ofile.puts ""
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

      def add_event(iday : Int32, text : String)
         puts "   Month.add_event Int #{iday}"
         
         da = @days[iday]?
         if da.nil?
            da = Day.new(iday)
            @days[iday] = da
         end
         da.add_event(text)
      end

      def write_md(ofile : File, year : Year)
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
                     s += "<br/>#{ev}"
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
   end
   
   class Year
      property y : Int32 = 0
      @months    = Hash(Int32, Month).new
      
      def initialize(iy : Int32)
         @y = iy
      end

      def add_event(imonth : Int32, iday : Int32, text : String)
         puts "   Year.add_event Int #{iday}-#{imonth}"
         
         mn = @months[imonth]?
         if mn.nil?
            mn = Month.new(imonth)
            @months[imonth] = mn
         end
         mn.add_event(iday, text)
      end

      def write_md(ofile : File)
          @months.each_key do |k|
             month = @months[k]
             ofile.puts "### #{month.to_s} #{@y}"
             ofile.puts ""
             
             month.write_md(ofile, self)
          end
      end
   end
   
   class Calendar
      def initialize
         @filename = ""
         @outname  = ""
         @fcontent = ""
         @years    = Hash(Int32, Year).new
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

      def add_event(iyear : Int32, imonth : Int32, iday : Int32, text : String)
         puts "   add_event Int #{iday}-#{imonth}-#{iyear}"
         
         yr = @years[iyear]?
         if yr.nil?
            yr = Year.new(iyear)
            @years[iyear] = yr
         end
         yr.add_event(imonth, iday, text)
      end

      def parse_line(line : String)
         puts "#{line}"
  
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

               iday   = day.to_i
               imonth = month.to_i
               iyear  = year.to_i
               puts "   as Int #{iday}-#{imonth}-#{iyear}"
               
               add_event(iyear, imonth, iday, text)
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
            ffile.each_line do |line|
               parse_line(line)
            end
            ffile.close
         rescue e
            STDERR.puts "file not found #{e}"
            exit(1)
         end
      end

      def write_md(ofile : File)
          @years.each_key do |k|
             #ofile.puts "## #{k}"
             #ofile.puts ""
             
             year = @years[k]
             year.write_md(ofile)
          end
      end

      def write_file
         # write md to file
         begin
            File.open(@outname, "w") do |ofile|
               write_md(ofile)
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
         write_file
      end
   end
   
   main = Calendar.new
   main.run
end

