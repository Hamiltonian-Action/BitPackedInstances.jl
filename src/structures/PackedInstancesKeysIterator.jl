
#==============================================================================#

"""

	PackedInstancesKeysIterator

Iterator over the keys of the associated [`AbstractPackedInstances`](@ref).

!!! warning
	It is advised that one ought to avoid utilising this type directly, in lieu
	consider employing the `keys` invocation.

See also:
	[`PackedInstancesValuesIterator`](@ref)

"""
struct PackedInstancesKeysIterator{T <: Tuple}

	@inline function PackedInstancesKeysIterator(
		source::AbstractPackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{T}()

	end

	@inline function PackedInstancesKeysIterator(
		source::PackedInstancesKeysIterator{T}
		) where {T <: Tuple}

		return new{T}()

	end

end

#===============================================================================
INTERNAL
===============================================================================#

@inline function query_content_mutability(
	::Union{
		PackedInstancesKeysIterator,
		Type{<: PackedInstancesKeysIterator}
		}
	)

	return false

end

@inline function query_name(
	::Union{
		PackedInstancesKeysIterator,
		Type{<: PackedInstancesKeysIterator}
		}
	)

	return "PackedInstancesKeysIterator"

end

#==============================================================================#
