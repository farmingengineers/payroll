class NameCompleter
  class NotFound < StandardError; end
  class Ambiguous < StandardError; end

  def initialize(options)
    @full_names = options.fetch(:full_names)
    @aliases = options.fetch(:aliases, {})
    @historical = options.fetch(:historical, false)
  end

  def lookup(name)
    aliased = match_alias(name) || name
    dname = aliased.downcase
    matches = @full_names.select { |n| n.downcase.start_with?(dname) }
    raise NotFound, "#{name.inspect} is not in the list!" \
      if matches.empty?
    raise Ambiguous, "#{name.inspect} matched more than one (#{matches.inspect})" \
      if matches.size > 1 && !@historical
    matches.first
  end

  private
  def match_alias(name)
    if match = @aliases[name]
      return match
    else
      key_match = @aliases.keys.find { |k| k.downcase == name.downcase }
      return @aliases[key_match]
    end
  end
end
