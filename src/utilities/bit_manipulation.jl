
#==============================================================================#

# CAUTION: Utilising `sizeof` is prone to error in the presence of metadata.
@inline function bit_count(
	::Type{S}
	) where {S <: Integer}

	return convert(S, count_zeros(zero(S)))

end

# Specifies number of bits necessary to encode this many configurations.
@inline function required_bits(
	X::Type
	)

	configuration_count = length(unique_instances(X))
	S = typeof(configuration_count)
	configuration_count = max(configuration_count, one(S))
	return bit_count(S) - convert(
		S, leading_zeros(configuration_count - one(S))
		)

end

# First set bit is at shifted position, total count up to span.
@inline function mask_bit_range(
	::Type{U}, span::Unsigned, shift::Unsigned
	) where {U <: Unsigned}

	return ~(~zero(U) << span) << shift

end

# CAUTION: Required bits must not exceed those available in the provided type.
# CAUTION: The provided type must not be a singleton.
@inline @generated function bits_from_value(
	::Type{U}, value::X, ::Val{shift}, ::Val{progression}
	) where {U <: Unsigned, X, shift, progression}

	if progression.validity
		output = quote
			@inline return to_integer(
				U, value, Val($progression)
				) << $shift
			end
	else
		# CAUTION: Explicit construction rather than quotation, painful.
		conditional_tree = :(;;)
		current_branch = :(;;)
		for (counter, instance) in enumerate(unique_instances(X))
			instance_bits = convert(U, counter - one(counter)) << shift
			clause = Expr(:call, :(==), :value, instance)
			body = Expr(:(=), :bits, instance_bits)
			if isone(counter)
				conditional_tree = Expr(:if, clause, body)
				current_branch = conditional_tree
			else
				new_branch = Expr(:elseif, clause, body)
				push!(current_branch.args, new_branch)
				current_branch = new_branch
			end
		end

		output = quote
			$conditional_tree
			return bits
			end
	end

	return output

end

# CAUTION: Required bits must not exceed those available in the provided type.
@inline @generated function value_from_bits(
	::Type{X}, bits::U, ::Val{shift}, ::Val{final_active_bits}
	) where {X, U <: Unsigned, shift, final_active_bits}

	span = convert(U, required_bits(X))
	if iszero(span)
		singleton = only(unique_instances(X))
		output = quote
			return $singleton
			end
	else
		mask = ifelse(
			final_active_bits,
			~zero(U),
			mask_bit_range(U, span, zero(U))
			)

		progression = check_arithmetic_progression(X)
		if progression.validity
			output = quote
				@inline return from_integer(
					X, bits >> $shift, Val($mask), Val($progression)
					)
				end
		else
			# Paranoid precaution should the latter type not suffice.
			unsigned_type = promote_type(U, Csize_t)
			# Enables optimiser to eliminate extraneous instruction.
			mask = convert(U, ~zero(unsigned_type) & mask)
			output = quote
				@inline temp = convert(
					$unsigned_type, (bits >> $shift) & $mask
					)
				@inbounds return unique_instances(X)[temp + one(temp)]
				end
		end
	end

	return output

end

#==============================================================================#
