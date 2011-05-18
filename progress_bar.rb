class ProgressBar
	MARKERS=['|','/','-','\\']	

	def initialize(total, options={})
		@total = total
		@length=options[:length] || 60
		@empty_char=options[:char] || "."
		@filled_char=options[:char] || "="
		@complete_message=options[:complete_message] || "Done!"
		@printed_progress=0
		@progress=0
		print_bar(true)
	end

	def progress
		@progress+=1
		print_bar
	end

	def complete
		@progress=@total
		print_bar
		print "\b#{@complete_message}\n"
		STDOUT.flush
	end

	#### Helpers
	private

	def print_bar(first_print = false)
		percent = @progress.to_f / @total
		visual_progress = (percent * @length).round

		new_bar = "["
		new_bar += "=" * visual_progress
		new_bar += "." * (@length - visual_progress)
		new_bar += "] "
		new_bar += sprintf("%3d",(percent*100).floor) + "% "
		new_bar += MARKERS[@progress % MARKERS.size]
		if not first_print
			print "\b" * new_bar.size
		end
		print new_bar
		STDOUT.flush
	end
end
