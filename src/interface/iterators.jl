
#==============================================================================#

#===============================================================================
ITERATE
===============================================================================#

@inline function Base.iterate(
	input::Union{
		PackedInstancesKeysIterator{T},
		Iterators.Reverse{PackedInstancesKeysIterator{T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {T <: Tuple}

	content = canonical_form(fieldtypes(T))
	successor = ifelse(input isa Iterators.Reverse, prevind, nextind)
	@inbounds output =
		(state in eachindex(content)) ?
		(
			content[state],
			successor(content, state)
			) :
		nothing
	return output

end

@inline function Base.iterate(
	input::Union{
		PackedInstancesValuesIterator{U, T},
		Iterators.Reverse{<: PackedInstancesValuesIterator{U, T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	if input isa Iterators.Reverse
		bit_pack = input.itr.bit_pack
		successor = prevind
	else
		bit_pack = input.bit_pack
		successor = nextind
	end
	@inbounds output =
		(state in eachindex(content)) ?
		(
			bit_pack[content[state]],
			successor(content, state)
			) :
		nothing
	return output

end

@inline function Base.iterate(
	input::Union{
		AbstractPackedInstances{U, T},
		Iterators.Reverse{<: AbstractPackedInstances{U, T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	if input isa Iterators.Reverse
		bit_pack = input.itr
		successor = prevind
	else
		bit_pack = input
		successor = nextind
	end
	@inbounds output =
		(state in eachindex(content)) ?
		(
			Pair(content[state], bit_pack[content[state]]),
			successor(content, state)
			) :
		nothing
	return output

end

#===============================================================================
ISDONE
===============================================================================#

@inline function Base.isdone(
	input::Union{
		PackedInstancesKeysIterator{T},
		Iterators.Reverse{PackedInstancesKeysIterator{T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	input::Union{
		PackedInstancesValuesIterator{U, T},
		Iterators.Reverse{<: PackedInstancesValuesIterator{U, T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	input::Union{
		AbstractPackedInstances{U, T},
		Iterators.Reverse{<: AbstractPackedInstances{U, T}}
		},
	state::Integer = ifelse(
		input isa Iterators.Reverse,
		lastindex(fieldtypes(T)),
		firstindex(fieldtypes(T))
		)
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

#==============================================================================#
