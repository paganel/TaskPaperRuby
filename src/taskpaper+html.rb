#!/usr/bin/ruby

# HTML export extensions

require_relative 'taskpaperdocument'
class TaskPaperDocument
	def to_html(only_type = nil, sidebar_mode = false)
		return (@root_item) ? @root_item.to_html(only_type, sidebar_mode) : ""
	end
	
	def to_sidebar
		return to_html(TaskPaperItem::TYPE_PROJECT, true)
	end
end

require_relative 'taskpaperitem'
class TaskPaperItem
	def to_html(only_type = nil, sidebar_mode = false)
		# HTML output, CSS-ready
		
		# If 'only_type' is specified, only that type of item will be output.
		# Types are found in TaskPaperItem: TYPE_TASK, etc.
		
		# If sidebar_mode is true, items will generate sidebar-suitable HTML instead.
		# This is only really of interest to projects (TYPE_PROJECT).

=begin
		The TaskPaperItem#to_html method takes account of any discrepancy in an item's nested depth in the graph and its actual indentation in the source file (via @extra_indent), generating an appropriate number of nested UL/LI tags so that the final HTML results accurately reflect the original indentation of each line (assuming suitable CSS is provided, e.g. to apply a margin-left to each UL).
=end
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			@extra_indent.times do output += "<li class='extra-indent'><ul class='extra-indent'>" end
			
			if !sidebar_mode and (!only_type or @type == only_type)
				
				tag_data_attrs = ""
				@tags.each do |t|
					tag_data_attrs += " data-#{t[:name]}='#{t[:value]}'"
				end
				
				proj_id = (@type == TYPE_PROJECT) ? "id='#{id_attr}' " : ""
				
				output += "<li #{proj_id}class='#{type_name.downcase}' data-type='#{type_name.downcase}'#{tag_data_attrs}>"
				
				posn = 0
			
				# Task prefix
				if @type == TYPE_TASK
					output += "<span class='task-prefix'><span class='task-marker'>#{content[0]}</span>"
					output += "#{@content[1]}</span>"
					posn += 2
				end
			
				# Metadata
				meta = metadata
				if meta.length == 0
					output += "<span class='display' display>#{@content[posn..-1]}</span>"
					posn = @content.length
				else
					metadata.each_with_index do |m, i|
						# Output any content from last end-point up to start of this entry
						range_start = m[:range].begin
						range_end = m[:range].end
						if posn < range_start
							output += "<span class='display' display>#{@content[posn..range_start - 1]}</span>"
							posn = range_start;
						end
						
						# Output this entry, suitably wrapped
						if m[:type] == "tag"
							tagname = m[:name]
							tagval = m[:value]
							# :name
							output += "<span class='tag' tag='data-#{tagname}' tagname='data-#{tagname}' display>@#{tagname}</span>"
							if tagval and tagval != ""
								# (
								output += "<span class='tag' tag='data-#{tagname}' display>(</span>"
							
								# :value
								output += "<span class='tag' tag='data-#{tagname}' tagvalue='#{tagval}' display>#{tagval}</span>"
							
								# )
								output += "<span class='tag' tag='data-#{tagname}' display>)</span>"
							end
						
						elsif m[:type] == "link"
							output += "<span class='link' link='#{m[:text]}' display><a href='#{m[:url]}' target='_blank'>#{m[:text]}</a></span>"
						end
						posn = range_end
					
						# If this is the last entry, output any remaining content afterwards
						if i == meta.length - 1
							content_len = @content.length
							if posn < content_len
								output += "<span class='display' display>#{@content[posn..-1]}</span>"
								posn = range_start;
							end
							posn = content_len;
						end
					end
				end
			elsif sidebar_mode
				if only_type and only_type == TYPE_PROJECT and (@type == TYPE_PROJECT)
					output += "<li class='#{type_name.downcase}' data-type='#{type_name.downcase}'#{tag_data_attrs}><a href='##{id_attr}' title='#{title}'>#{title}</a>"
				end
			end
			if @children and @children.length > 0
				output += "#{@@linebreak}<ul>#{@@linebreak}"
			end
		end
		@children.each do |child|
			output += child.to_html(only_type, sidebar_mode)
		end
		if @children and @children.length > 0
			output += "#{@@linebreak}</ul>#{@@linebreak}"
		end
		if @type != TYPE_NULL
			output += "</li>#{@@linebreak}"
			@extra_indent.times do output += "</ul></li>" end
		end
		if @type == TYPE_NULL
			if sidebar_mode
				output = "<ul class='taskpaper-root sidebar'><li class='extra-indent' data-type='project'><a href='#top' title='Home'>Home</a><ul class='extra-indent'>#{output}</ul></li></ul>"
			else
				output = "<ul class='taskpaper-root'>#{output}</ul>"
			end
		end
		return output
	end
	
	def to_sidebar
		return to_html(TaskPaperItem::TYPE_PROJECT, true)
	end
end