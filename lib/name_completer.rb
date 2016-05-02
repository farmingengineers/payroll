class NameCompleter
  def initialize(options)
    @full_names = options.fetch(:full_names)
  end

  def lookup(name)
    @full_names.find { |n| n.start_with?(name) }
  end
end
