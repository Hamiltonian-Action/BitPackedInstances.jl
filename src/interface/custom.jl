
#==============================================================================#

"""

	overwrite!(
		::MutablePackedInstances[, values...]
		)

Optimised content modification suitable for bulk operation.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = MutablePackedInstances(UInt8, earth);

julia> match_content(bit_pack, earth)
true

julia> overwrite!(bit_pack, air);

julia> match_content(bit_pack, air)
true
```

"""
@inline @generated function overwrite!(
	bit_pack::MutablePackedInstances{U, T}, values...
	) where {U <: Unsigned, T <: Tuple}

	mismatch = findfirst(!in(fieldtypes(T)), values)
	isnothing(mismatch) || throw(KeyError(mismatch))
	return quote
		@inline bit_pack.bits = _DataContainer(bit_pack, values...).bits
		return bit_pack
		end

end

"""

	discard(
		::AbstractPackedInstances[, ::Type...]
		)

Constructs a new object matching the argument's concrete subtype, wherein the
provided types have been removed if they are found to be within its content.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8, fire);

julia> haskey(bit_pack, Elements)
true

julia> bit_pack = discard(bit_pack, Elements);

julia> haskey(bit_pack, Elements)
false
```

"""
@inline function discard(
	bit_pack::AbstractPackedInstances, keys::Type...
	)

	constructor = query_constructor(bit_pack)
	@inline return constructor(_discard(bit_pack, keys...))

end

"""

	match_content(
		::AbstractPackedInstances[, values...]
		)

Optimised content matching suitable for constant folding during compilation.

!!! note "Multiplicity"
	Given that only one `instances` value can be stored for each individual
	type, values of a common type must also satisfy equality amidst themselves.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8, water, north, blue);

julia> match_content(bit_pack, north, blue)
true

julia> match_content(bit_pack, water, fire)
false
```

"""
@inline @generated function match_content(
	bit_pack::AbstractPackedInstances{U, T}, values...
	) where {U <: Unsigned, T <: Tuple}

	if isempty(values)
		# CAUTION: Handle separately due to specialised semantics.
		return quote
			return true
			end
	end

	content = fieldtypes(T)
	shifts = (convert(U, required_bits(x)) for x in content)
	# These are required later for indexable referencing.
	target_types = values
	# Eliminate redundancy.
	unique_target_types = unique(target_types)

	# Feeds forward into future iterations.
	pattern = quote
		bits = zero(U)
		end
	mask = zero(U)
	subclauses = Expr[]
	sizehint!(subclauses, length(unique_target_types); first = true)

	for target in unique_target_types

		# Check whether it matches any of the content.
		shift = zero(U)
		search_success = false
		for (span, variety) in zip(shifts, content)
			search_success = variety == target
			search_success && break
			shift += span
		end

		search_success || throw(KeyError(target))

		span = convert(U, required_bits(target))
		iszero(span) && continue
		mask |= mask_bit_range(U, span, shift)

		subclause_indices = findall(==(target), target_types)
		value_index = last(subclause_indices)

		# Ensure repeated values are equivalent.
		count = length(subclause_indices)
		count -= one(count)
		if !iszero(count)
			# CAUTION: Explicit construction rather than quotation, painful.
			subclause_indices = Iterators.take(subclause_indices, count)
			comparison_expressions = (
				Expr(:ref, :values, index) for index in subclause_indices
				)
			subclause_expression = Expr(
				:comparison,
				Iterators.flatten(
					zip(
						comparison_expressions,
						Iterators.repeated(:(==), count)
						)
					)...,
				Expr(:ref, :values, value_index),
				)
			pushfirst!(subclauses, subclause_expression)
		end

		# Permissible given that singletons have been addressed.
		progression = check_arithmetic_progression(target)
		if progression.validity
			# Encourage inlining when encoding is efficient.
			pattern = quote
				$pattern
				@inbounds @inline bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		else
			pattern = quote
				$pattern
				@inbounds bits |= bits_from_value(
						U, values[$value_index], Val($shift), Val($progression)
						)
				end
		end

	end

	if iszero(mask)
		# Consists entirely of singletons.
		output = quote
			return true
			end
	else
		count = length(subclauses)
		clause = :(bit_pack.bits & $mask == bits)

		if !iszero(count)
			# Collapse subclauses.
			combined = first(subclauses)
			for subclause in Iterators.drop(subclauses, one(count))
				combined = Expr(:(&&), subclause, combined)
			end
			combined = Expr(:(&&), clause, combined)
			output = quote
				@inbounds return $combined
				end
		else
			output = quote
				return $clause
				end
		end

		output = quote
			$pattern
			$output
			end
	end

	return output

end

"""

	is_encodable(
		::Type
		)

Queries whether it is permissible to utilise [`BitPackedInstances`](@ref) to
encode the `instances` of the provided argument.

!!! warning World age
	Due to extensively employing `@generated` function definitions that observe
	some aspects of the global state, output stability cannot be guaranteed.

See also:
	[`encoding_bits`](@ref),
	[`can_encode`](@ref)

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> using BitPackedInstances

julia> is_encodable(CardinalDirections)
true

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> is_encodable(ColourChannels)
false
```

"""
@inline function is_encodable(
	X::Type
	)

	output = false
	try
		# Verifies whether `@generated` functions are operational.
		@inline value_from_bits(X, 0x0, Val(0x0), Val(false))
		output = true
	catch
		# Nothing need be done here.
	end
	return output

end

"""

	encoding_bits(
		::Type
		)

Queries how many bits are consumed by [`BitPackedInstances`](@ref) in encoding
the `instances` of the provided argument.

!!! warning World age
	Due to extensively employing `@generated` function definitions that observe
	some aspects of the global state, output stability cannot be guaranteed.

See also:
	[`is_encodable`](@ref),
	[`can_encode`](@ref)

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> using BitPackedInstances

julia> encoding_bits(CardinalDirections) == 2
true

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> ismissing(encoding_bits(ColourChannels))
true
```

"""
@inline function encoding_bits(
	X::Type
	)

	output = missing
	try
		# Verifies whether `@generated` functions are operational.
		@inline value_from_bits(X, 0x0, Val(0x0), Val(false))
		output = required_bits(X)
	catch
		# Nothing need be done here.
	end
	return output

end

"""

	can_encode(
		::Union{
			AbstractPackedInstances,
			Type{<: AbstractPackedInstances}
			},
		::Type
		)

Queries whether the provided argument is indeed able to encode the given type.

!!! warning World age
	Due to extensively employing `@generated` function definitions that observe
	some aspects of the global state, output stability cannot be guaranteed.

See also:
	[`is_encodable`](@ref),
	[`encoding_bits`](@ref)

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> @enum Numbers begin natural; integer; rational; real; complex; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8);

julia> can_encode(bit_pack, Elements)
true

julia> can_encode(bit_pack, Numbers)
true

julia> bit_pack = ImmutablePackedInstances(bit_pack, fire, west, red);

julia> can_encode(bit_pack, Elements)
true

julia> can_encode(bit_pack, Numbers)
false
```

"""
@inline function can_encode(
	::Union{
		AbstractPackedInstances{U, T},
		Type{<: AbstractPackedInstances{U, T}}
		},
	X::Type
	) where {U <: Unsigned, T <: Tuple}

	available_bits = bit_count(U) - sum(
		(convert(U, required_bits(x)) for x in fieldtypes(T));
		init = zero(U)
		)
	output = false
	try
		# Verifies whether `@generated` functions are operational.
		@inline value_from_bits(X, 0x0, Val(0x0), Val(false))
		output = X in fieldtypes(T) || required_bits(X) <= available_bits
	catch
		# Nothing need be done here.
	end
	return output

end

"""

	encoding_type(
		::Union{
			AbstractPackedInstances,
			Type{<: AbstractPackedInstances}
			}
		)

Queries the underlying unsigned type that is being utilised by the provided
argument in encoding its content.

# Examples

```jldoctest
julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8);

julia> encoding_type(bit_pack)
UInt8

julia> bit_pack = ImmutablePackedInstances(UInt32);

julia> encoding_type(bit_pack)
UInt32
```

"""
@inline function encoding_type(
	::Union{
		AbstractPackedInstances{U},
		Type{<: AbstractPackedInstances{U}}
		}
	) where {U <: Unsigned}

	return U

end

"""

	consumed_capacity(
		::Union{
			AbstractPackedInstances,
			Type{<: AbstractPackedInstances}
			}
		)

Queries the number of consumed bits that are being utilised by the provided
argument in encoding its content.

See also:
	[`available_capacity`](@ref)

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt32, north, alpha);

julia> consumed_capacity(bit_pack) == 4
true
```

"""
@inline function consumed_capacity(
	::Union{
		AbstractPackedInstances{U, T},
		Type{<: AbstractPackedInstances{U, T}}
		}
	) where {U <: Unsigned, T <: Tuple}

	return sum(
		(convert(U, required_bits(x)) for x in fieldtypes(T));
		init = zero(U)
		)

end

"""

	available_capacity(
		::Union{
			AbstractPackedInstances,
			Type{<: AbstractPackedInstances}
			}
		)

Queries the number of available bits that can be utilised by the provided
argument in encoding additional content.

See also:
	[`consumed_capacity`](@ref)

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt32, north, alpha);

julia> available_capacity(bit_pack) == 28
true
```

"""
@inline function available_capacity(
	::Union{
		AbstractPackedInstances{U, T},
		Type{<: AbstractPackedInstances{U, T}}
		}
	) where {U <: Unsigned, T <: Tuple}

	return bit_count(U) - sum(
		(convert(U, required_bits(x)) for x in fieldtypes(T));
		init = zero(U)
		)

end

#==============================================================================#
