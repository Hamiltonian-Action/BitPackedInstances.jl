
#==============================================================================#

"""

	AbstractPackedInstances{U <: Unsigned, T <: Tuple}

Abstract type signifying that `fieldtypes(T)` consists solely of unique entries,
all of which support querying their `instances`, and that a singular bit-field
(of type `U`) is densely encoding one such instance of each of them, which can
all either be keyed via their associated type or accessed as a property through
their corresponding symbol.

!!! compat "Extensibility"
	On account of being intimately intertwined with the employed underlying
	bit representations, this abstract type is not designed to be extensible
	but rather to unify the interfaces provided by [`BitPackedInstances`](@ref)

See also:
	[`MutablePackedInstances`](@ref),
	[`ImmutablePackedInstances`](@ref)

"""
abstract type AbstractPackedInstances{U <: Unsigned, T <: Tuple} end

"""

	AbstractPackedInstances(
		::AbstractPackedInstances[, values...]
		)

Aliases for the corresponding method of the argument's concrete subtype.
"""
@inline function AbstractPackedInstances(
	bit_pack::AbstractPackedInstances, values...
	)

	constructor = query_constructor(bit_pack)
	@inline return constructor(bit_pack, values...)

end

"""

	AbstractPackedInstances(
		::Type{<: Unsigned}, ::AbstractPackedInstances
		)

Aliases for the corresponding method of the argument's concrete subtype.
"""
@inline function AbstractPackedInstances(
	::Type{U_new}, bit_pack::AbstractPackedInstances
	) where {U_new <: Unsigned}

	constructor = query_constructor(bit_pack)
	@inline return constructor(U_new, bit_pack)

end

#==============================================================================#
