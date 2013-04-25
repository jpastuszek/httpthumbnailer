class Stats < Controler
	def self.<<(stats)
		(@@stats ||= []) << stats
	end
	
	self.define do
		all_stats = {}
		@@stats.each do |stats|
			stats.class::MEMBERS.each.with_index.map do |stat, index|
				all_stats[stat] = stats[index]
			end
		end

		on :stat do |stat|
			write_plain 200, all_stats[stat.to_sym].to_s || raise(ArgumentError, "unknown stat #{stat}")
		end

		on true do
			write_plain 200, all_stats.map{|stat, value| "#{stat}: #{value}"}.join("\n")
		end
	end
end

