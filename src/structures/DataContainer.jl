
#==============================================================================#

# Utilised internally to facilitate transformations.
struct _DataContainer{U <: Unsigned, T <: Tuple}

	bits::U

	@inline function _DataContainer(
		bits::U, ::Type{T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(bits)

	end

end

# CAUTION: Requires that argument types support querying their instances.
@inline @generated function _DataContainer(
	::Type{U}, values...
	) where {U <: Unsigned}

	# These are required later for indexable referencing.
	data_types = values
	# Eliminate redundancy.
	unique_data_types = unique(data_types)
	shifts = (required_bits(x) for x in unique_data_types)

	# CAUTION: The summation may potentially overflow, handle it properly.
	sums = accumulate(+, shifts; init = zero(U))
	isempty(sums) || issorted(sums) && last(sums) <= bit_count(U) ||
		throw(ArgumentError(error_string_construction(U)))

	# Feeds forward into future iterations.
	output = quote
		bits = zero(U)
		end
	shift = zero(U)

	for (span, data_type) in zip(shifts, unique_data_types)
		iszero(span) && continue
		# Latest value overwrites all previous ones.
		value_index = findlast(==(data_type), data_types)
		# Permissible given that singletons have been addressed.
		progression = check_arithmetic_progression(data_type)
		if progression.validity
			# Encourage inlining when encoding is efficient.
			output = quote
				$output
				@inbounds @inline bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		else
			output = quote
				$output
				@inbounds bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		end
		shift += convert(U, span)
	end

	tuple_type = Tuple{unique_data_types...}
	return quote
		$output
		@inline return _DataContainer(bits, $tuple_type)
		end

end

# CAUTION: Requires that argument types support querying their instances.
@inline @generated function _DataContainer(
	bit_pack::AbstractPackedInstances{U, T}, values...
	) where {U <: Unsigned, T <: Tuple}

	existing_data_types = fieldtypes(T)
	existing_shifts =
		(convert(U, required_bits(x)) for x in existing_data_types)
	# These are required later for indexable referencing.
	new_data_types = values
	data_types = (existing_data_types..., new_data_types...)
	# Eliminate redundancy.
	data_types = unique(data_types)

	# CAUTION: The summation may potentially overflow, handle it properly.
	sums = accumulate(
		+, (required_bits(x) for x in data_types); init = zero(U)
		)
	isempty(sums) || issorted(sums) && last(sums) <= bit_count(U) ||
		throw(ArgumentError(error_string_expansion(U, T)))

	# Perform masking with minimal operations.
	mask = zero(U)
	shift = zero(U)
	for (span, variety) in zip(existing_shifts, existing_data_types)
		if !iszero(span) && variety in new_data_types
			mask |= mask_bit_range(U, span, shift)
		end
		shift += span
	end
	if iszero(mask)
		# Overwrite nil bits.
		output = quote
			bits = bit_pack.bits
			end
	elseif mask == mask_bit_range(U, shift, zero(U))
		# Overwrite everything.
		output = quote
			bits = zero(U)
			end
	else
		mask = ~mask
		output = quote
			bits = bit_pack.bits & $mask
			end
	end

	# Feeds forward into future iterations.
	suffix_shift = zero(U)

	for data_type in unique(new_data_types)
		span = convert(U, required_bits(data_type))
		iszero(span) && continue
		# Latest value overwrites all previous ones.
		value_index = findlast(==(data_type), new_data_types)

		# Check whether it matches an existing type.
		shift = zero(U)
		search_success = false
		for (span, variety) in zip(existing_shifts, existing_data_types)
			search_success = variety == data_type
			search_success && break
			shift += span
		end

		if !search_success
			# Brand new type, apply suffix then increment it.
			shift += suffix_shift
			suffix_shift += span
		end

		# Permissible given that singletons have been addressed.
		progression = check_arithmetic_progression(data_type)
		if progression.validity
			# Encourage inlining when encoding is efficient.
			output = quote
				$output
				@inbounds @inline bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		else
			output = quote
				$output
				@inbounds bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		end
	end

	tuple_type = Tuple{data_types...}
	return quote
		$output
		@inline return _DataContainer(bits, $tuple_type)
		end

end

# Alter the encoding unsigned type.
@inline function _DataContainer(
	::Type{U_new}, bit_pack::AbstractPackedInstances{U, T}
	) where {U_new <: Unsigned, U <: Unsigned, T <: Tuple}

	sum(
		(convert(U, required_bits(x)) for x in fieldtypes(T));
		init = zero(U)
		) <= bit_count(U_new) ||
			throw(ArgumentError(error_string_conversion(U_new, U, T)))
	@inline return _DataContainer(convert(U_new, bit_pack.bits), T)

end

@inline @generated function _discard(
	bit_pack::AbstractPackedInstances{U, T}, keys::Type...
	) where {U <: Unsigned, T <: Tuple}

	existing_data_types = fieldtypes(T)
	# Eliminate redundancy and Type{X} wrapper.
	discarded_data_types = unique((unwrap_type(x) for x in keys))
	# Retain only pertinent data.
	discarded_data_types =
		filter(in(existing_data_types), discarded_data_types)
	data_types = filter(!in(discarded_data_types), existing_data_types)
	tuple_type = Tuple{data_types...}

	if isempty(data_types)
		# Discard everything.
		return quote
			@inline return _DataContainer(zero(U), Tuple{})
			end
	elseif iszero(
		# No need to worry about overflow, discarded is contained in existing.
		sum(
			(convert(U, required_bits(x)) for x in discarded_data_types);
			init = zero(U)
			)
		)

		# Whatever is being discarded is encoded with nil bits.
		return quote
			@inline return _DataContainer(bit_pack.bits, $tuple_type)
			end

	end

	#===========================================================================
	HENCEFORTH, THERE EXISTS AT LEAST TWO SEGMENTS.
	===========================================================================#

	# Group contiguous sections of bits together. Mark kept segments as true.
	segment_varieties = falses(bit_count(U))
	segment_shifts = zeros(U, bit_count(U))
	varieties_index = firstindex(segment_varieties)
	shifts_index = firstindex(segment_shifts)

	current_variety = !(first(existing_data_types) in discarded_data_types)
	shift = zero(U)
	for data_type in existing_data_types
		span = convert(U, required_bits(data_type))
		iszero(span) && continue
		variety = !(data_type in discarded_data_types)
		if variety != current_variety
			@inbounds segment_varieties[varieties_index] = current_variety
			@inbounds segment_shifts[shifts_index] = shift
			varieties_index = nextind(segment_varieties, varieties_index)
			shifts_index = nextind(segment_shifts, shifts_index)
			current_variety = variety
			shift = zero(U)
		end
		shift += span
	end
	# Mark down the final segment.
	@inbounds segment_varieties[varieties_index] = current_variety
	@inbounds segment_shifts[shifts_index] = shift

	# Utilised in setting up the output bits.
	shift = popfirst!(segment_shifts)
	mask = mask_bit_range(U, shift, zero(U))

	if varieties_index == nextind(
		segment_varieties, firstindex(segment_varieties)
		)

		# Either KEEP DISCARD or DISCARD KEEP
		if first(segment_varieties)
			return quote
				@inline return _DataContainer(
					bit_pack.bits & $mask, $tuple_type
					)
				end
		else
			return quote
				@inline return _DataContainer(
					bit_pack.bits >> $shift, $tuple_type
					)
				end
		end

	end

	#===========================================================================
	HENCEFORTH, THERE EXISTS AT LEAST THREE SEGMENTS.
	===========================================================================#

	if popfirst!(segment_varieties)
		output = quote
			reference_bits = bit_pack.bits
			bits = reference_bits & $mask
			end
		read_shift = shift
		write_shift = shift
	else
		output = quote
			reference_bits = bit_pack.bits
			bits = reference_bits >> $shift
			end
		read_shift = shift
		# Next segment is guaranteed to be true, just take its shift.
		shift, _ = popfirst!(segment_shifts), popfirst!(segment_varieties)
		mask = mask_bit_range(U, shift, zero(U))
		output = quote
			$output
			bits &= $mask
			end
		read_shift += shift
		write_shift = shift
	end

	for (span, variety) in zip(segment_shifts, segment_varieties)
		iszero(span) && break
		if variety
			mask = mask_bit_range(U, span, read_shift)
			delta = read_shift - write_shift
			output = quote
				$output
				bits |= (reference_bits & $mask) >> $delta
				end
			write_shift += span
		end
		read_shift += span
	end

	return quote
		$output
		@inline return _DataContainer(bits, $tuple_type)
		end

end

#==============================================================================#
