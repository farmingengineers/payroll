class NameCompleter
  def initialize(options)
    @full_names = options.fetch(:full_names)
    @results = Hash.new do |h,k|
      h[k] = @full_names.find { |n| n.start_with?(k) } || k
    end
  end

  def lookup(name)
    @results[name]
  end
end
