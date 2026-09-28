
#==============================================================================#

function truncate_string(
	input::AbstractString, width::Integer;
	truncation_mark::Union{AbstractChar, AbstractString} = '…'
	)

	width = max(width, zero(width))
	mark_width = textwidth(truncation_mark)

	textwidth(input) <= width && return input
	width < mark_width && return ""

	# CAUTION: The summation may potentially overflow, handle it properly.
	checked_width, flag = Base.Checked.add_with_overflow(
		textwidth(first(input)), mark_width
		)
	(flag || width < checked_width) && return truncation_mark

	upper = firstindex(input)
	elapsed = checked_width
	while true
		next = nextind(input, upper)
		@inbounds temp, flag = Base.Checked.add_with_overflow(
			elapsed, textwidth(input[next])
			)
		(flag || width < temp) && break
		upper = next
		elapsed = temp
	end
	@inbounds return string((@view input[begin : upper]), truncation_mark)

end

#===============================================================================
ITERATORS
===============================================================================#

function Base.show(
	io::IO,
	iterator::Union{
		PackedInstancesKeysIterator,
		PackedInstancesValuesIterator
		}
	)

	minimum_count = 0x8
	separator = ", "

	count = length(iterator)
	initial, final = ifelse(
		query_content_mutability(iterator),
		('[', ']'),
		('(', ')')
		)

	print(io, initial)

	first_entry = true
	if get(io, :limit, false) && minimum_count < count
		leading = Iterators.take(iterator, minimum_count >> 0x1)
		trailing = Iterators.drop(iterator, count - (minimum_count >> 0x1))

		for element in leading
			first_entry || print(io, separator)
			first_entry = false
			show(io, element)
		end
		print(io, separator, "… ")
		for element in trailing
			print(io, separator)
			show(io, element)
		end
	else
		for element in iterator
			first_entry || print(io, separator)
			first_entry = false
			show(io, element)
		end
	end

	print(io, final)

	return nothing

end

function Base.show(
	io::IO,
	::MIME"text/plain",
	iterator::Union{
		PackedInstancesKeysIterator,
		PackedInstancesValuesIterator
		}
	)

	padding = string('\n', rpad("", 0x2))
	padding_width = textwidth(padding)
	# Dimensions could be pathologically small.
	height_threshold = 0x4
	width_threshold = padding_width << 0x3
	# Account for the additional lines.
	height_offset = 0x3
	# Leave one padding width free on either side.
	width_offset = padding_width << 0x1

	count = length(iterator)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(count), "entry", "entries")
	print(io, query_name(iterator), " encoding ($count) $singular_or_plural")

	if get(io, :compact, false) || iszero(count)
		print(io, '.')
		return nothing
	end

	print(io, ':')

	# Query dimensions and adjust according to context.
	raw_height, raw_width = unsigned.(displaysize(io))
	height, width = ifelse(
		get(io, :limit, false),
		(raw_height, raw_width),
		(typemax(raw_height), typemax(raw_width))
		)

	if height <= width_offset
		print(io, " …")
		return nothing
	elseif width < width_threshold
		print(io, padding, '⋮')
		return nothing
	end

	height -= height_offset
	width -= width_offset

	if get(io, :limit, false)
		for (counter, element) in enumerate(iterator)
			print(io, padding)
			if counter == height < count
				print(io, '⋮')
				break
			end
			element_string = repr(element; context = io)
			print(io, truncate_string(element_string, width))
		end
	else
		for element in iterator
			print(io, padding)
			show(io, element)
		end
	end

	return nothing

end

#===============================================================================
ABSTRACTPACKEDINSTANCES
===============================================================================#

function Base.show(
	io::IO,
	bit_pack::AbstractPackedInstances
	)

	minimum_count = 0x8
	separator = ", "

	counter = ifelse(get(io, :limit, false), minimum_count, length(bit_pack))

	print(io, query_name(bit_pack), '(')
	show(io, encoding_type(bit_pack))

	for (_, value) in bit_pack
		print(io, separator)
		if iszero(counter)
			print(io, '…')
			break
		end
		show(io, value)
		counter -= one(counter)
	end

	print(io, ')')

	return nothing

end

function Base.show(
	io::IO,
	::MIME"text/plain",
	bit_pack::AbstractPackedInstances
	)

	# Virtuous width, heretical character.
	padding = string('\n', rpad("", 0x2))
	padding_width = textwidth(padding)
	arrow = " => "
	# Dimensions could be pathologically small.
	height_threshold = 0x4
	width_threshold = padding_width << 0x3
	# Account for the additional lines.
	height_offset = 0x3
	# Leave one padding width free on either side plus room for the arrow.
	width_offset = (padding_width << 0x1) + textwidth(arrow)

	count = length(bit_pack)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(count), "entry", "entries")
	print(io, query_name(bit_pack), " encoding ($count) $singular_or_plural")

	if get(io, :compact, false) || iszero(count)
		print(io, '.')
		return nothing
	end

	print(io, ':')

	# Query dimensions and adjust according to context.
	raw_height, raw_width = unsigned.(displaysize(io))
	height, width = ifelse(
		get(io, :limit, false),
		(raw_height, raw_width),
		(typemax(raw_height), typemax(raw_width))
		)

	if height <= height_threshold
		print(io, " …")
		return nothing
	elseif width < width_threshold
		print(io, padding, '⋮', arrow, '⋮')
		return nothing
	end

	height -= height_offset
	width -= width_offset

	# Nested elements should present themselves compactly unless requested.
	nested_io = IOContext(io, :compact => get(io, :compact, true))

	if get(io, :limit, false)
		# Utilised for constructing the output.
		string_count = ifelse(height < count, height - one(height), count)
		key_strings = AbstractString[]
		value_strings = AbstractString[]
		sizehint!(key_strings, string_count)
		sizehint!(value_strings, string_count)
		key_width = zero(width)
		value_width = zero(width)

		# Collect entries and track the maximum observed width.
		for (counter, (key, value)) in enumerate(bit_pack)
			key_string = repr(key; context = nested_io)
			value_string = repr(value; context = nested_io)
			push!(key_strings, key_string)
			push!(value_strings, value_string)
			key_width = clamp(textwidth(key_string), key_width, width)
			value_width = clamp(textwidth(value_string), value_width, width)
			counter == string_count && break
		end

		# CAUTION: The summation may potentially overflow, handle it properly.
		total_width, flag = Base.Checked.add_with_overflow(
			key_width, value_width
			)
		if flag || width < total_width
			# Saturate to half and provide the remainder.
			key_width = min(key_width, width >> 0x1)
			value_width = min(value_width, width - key_width)
		end

		for (key_string, value_string) in zip(key_strings, value_strings)
			print(io, padding)
			print(io, rpad(truncate_string(key_string, key_width), key_width))
			print(io, arrow)
			print(io, truncate_string(value_string, value_width))
		end
		string_count != count && print(io, padding, '⋮', arrow, '⋮')
	else
		for (key, value) in bit_pack
			print(io, padding)
			show(nested_io, key)
			print(io, arrow)
			show(nested_io, value)
		end
	end

	return nothing

end

#==============================================================================#
