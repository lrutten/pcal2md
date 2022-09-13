require "option_parser"
require "string_scanner"

module Pcal2md
   VERSION = "0.9.1"

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

      def write_ics(ofile : File, month : Month)
          @events.each do |txt|
             ofile.puts "dag #{txt}"
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
         puts "month"

         @days.each_key do |k|
            day = @days[k]
            day.write_ics(ofile, self)
         end
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

      def write_ics(ofile : File)
          @months.each_key do |k|
             month = @months[k]
             puts "month"
             
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

      def write_md2(ofile : File)
          @years.each_key do |k|
             #ofile.puts "## #{k}"
             #ofile.puts ""
             
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
          @years.each_key do |k|
             puts "year"
             year = @years[k]
             year.write_ics(ofile)
          end
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
            write_md
         end
      end
   end
   
   main = Calendar.new
   main.run
end

