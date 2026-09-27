
#==============================================================================#

@inline function Base.keys(
	bit_pack::AbstractPackedInstances
	)

	return PackedInstancesKeysIterator(bit_pack)

end

@inline function Base.values(
	bit_pack::AbstractPackedInstances
	)

	return PackedInstancesValuesIterator(bit_pack)

end

@inline function Base.pairs(
	bit_pack::AbstractPackedInstances
	)

	return bit_pack

end

@inline function Base.eachindex(
	bit_pack::AbstractPackedInstances
	)

	return keys(bit_pack)

end

@inline function Base.keytype(
	::Union{
		AbstractPackedInstances{U, T},
		Type{<: AbstractPackedInstances{U, T}}
		}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(fieldtypes(T))

end

@inline function Base.valtype(
	::Union{
		AbstractPackedInstances{U, T},
		Type{<: AbstractPackedInstances{U, T}}
		}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(map(ComposedFunction(first, instances), fieldtypes(T)))

end

@inline function Base.haskey(
	bit_pack::AbstractPackedInstances, key
	)

	return key in keys(bit_pack)

end

@inline function Base.get(
	failure::Base.Callable, bit_pack::AbstractPackedInstances, key
	)

	return haskey(bit_pack, key) ? bit_pack[key] : failure()

end

@inline function Base.get(
	bit_pack::AbstractPackedInstances, key, default
	)

	return haskey(bit_pack, key) ? bit_pack[key] : default

end

@inline function Base.getkey(
	bit_pack::AbstractPackedInstances, key, default
	)

	return ifelse(haskey(bit_pack, key), key, default)

end

#==============================================================================#
