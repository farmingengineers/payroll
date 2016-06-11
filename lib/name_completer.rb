class NameCompleter
  class NotFound < StandardError; end
  class Ambiguous < StandardError; end

  def initialize(options)
    @full_names = options.fetch(:full_names)
  end

  def lookup(name)
    dname = name.downcase
    matches = @full_names.select { |n| n.downcase.start_with?(dname) }
    raise NotFound, "#{name.inspect} is not in the list!" \
      if matches.empty?
    raise Ambiguous, "#{name.inspect} matched more than one (#{matches.inspect})" \
      if matches.size > 1
    matches.first
  end
end
