
#==============================================================================#

"""

	PackedInstancesValuesIterator

Iterator over the values of the associated [`AbstractPackedInstances`](@ref).

!!! warning
	It is advised that one ought to avoid utilising this type directly, in lieu
	consider employing the `values` invocation.

See also:
	[`PackedInstancesKeysIterator`](@ref)

"""
struct PackedInstancesValuesIterator{
	U <: Unsigned, T <: Tuple, PI <: AbstractPackedInstances{U, T}
	}

	bit_pack::PI

	@inline function PackedInstancesValuesIterator(
		source::PI
		) where {
			U <: Unsigned, T <: Tuple, PI <: AbstractPackedInstances{U, T}
			}

		return new{U, T, PI}(source)

	end

	@inline function PackedInstancesValuesIterator(
		source::PackedInstancesValuesIterator{U, T, PI}
		) where {
			U <: Unsigned, T <: Tuple, PI <: AbstractPackedInstances{U, T}
			}

		return new{U, T, PI}(source.bit_pack)

	end

end

#===============================================================================
INTERNAL
===============================================================================#

@inline function query_content_mutability(
	::Union{
		PackedInstancesValuesIterator{U, T, PI},
		Type{<: PackedInstancesValuesIterator{U, T, PI}}
		}
	) where {
		U <: Unsigned, T <: Tuple, PI <: AbstractPackedInstances{U, T}
		}

	return ismutabletype(PI) && any(
		!ComposedFunction(iszero, required_bits),
		fieldtypes(T)
		)

end

@inline function query_name(
	::Union{
		PackedInstancesValuesIterator,
		Type{<: PackedInstancesValuesIterator}
		}
	)

	return "PackedInstancesValuesIterator"

end

#==============================================================================#
