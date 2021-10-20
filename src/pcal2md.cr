require "option_parser"
require "string_scanner"

module Pcal2md
   VERSION = "0.9.0"

   class Calendar
      def initialize
         @filename = ""
         @fcontent = ""
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
            end
         else
            puts "   empty line"
         end
      end

      def read_file
         # read the list of disks
         begin
            ffile = File.new(@filename)
            #@fcontent = ffile.gets_to_end
            ffile.each_line do |line|
               parse_line(line)
            end
            ffile.close
         rescue
            STDERR.puts "file not found"
            exit(1)
         end
      end


      def run
         puts "start2"
         get_options
         puts "get options ok"
         puts "file name #{@filename}"
         read_file
      end
   end
   
   main = Calendar.new
   main.run
end

