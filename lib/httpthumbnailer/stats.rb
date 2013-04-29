module Stats
	def def_stats(*stat_names)
		@@local_stats ||= {}
		stats_class = eval "Raindrops::Struct.new(#{stat_names.map{|s| ":#{s.to_s}"}.join(', ')})"
		@@local_stats[self] = stats_class.new
	end

	def stats
		@@local_stats[self]
	end
end

