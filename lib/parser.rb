require "yaml"

require_relative "../lib/name_completer"
require_relative "../lib/timesheets"

# Reads entries from a file.
#
# Argument: path to input file.
#
# Return: array of hashes. Each hash has keys :start, :end, :name
#/
#/ input looks like this:
#/
#/    9/2
#/    Joe Bob 7:52 8:19
#/    9/3
#/    Job Bob 7:55-9:30
#/    Mel Adams 8:01 9:01
#/
#/ or this
#/
#/    Joe Bob
#/    9/2 7:52-8:19
#/    9/3 7:55 9:30
#/
#/    Mel Adams
#/    9/3 8:01 9:01
#/
#/ or, with employees.yml like this
#/
#/    employees:
#/    - Joe Bob
#/    - Mel Adams
#/
#/ and input like this
#/
#/    Joe 7:52 - 8:19
def read_input(path, options)
  config = YAML.load(File.read(File.expand_path("../employees.yml", File.dirname(__FILE__))))

  employees = config["employees"]
  aliases = config["aliases"]
  if options[:historical]
    employees += config["former_employees"]
  end

  parse_opts = {}
  parse_opts[:log] = $stderr if options[:verbose]
  parse_opts[:names] = NameCompleter.new(:full_names => employees, :aliases => aliases, :historical => options[:historical])
  parse_opts[:year] = options[:year] if options[:year]

  File.open(path) do |f|
    Timesheets.parse_raw(f, parse_opts)
  end
end
