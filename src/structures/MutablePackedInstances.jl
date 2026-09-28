
#==============================================================================#

"""

	MutablePackedInstances{U <: Unsigned, T <: Tuple}

Concrete instantiation of [`AbstractPackedInstances`](@ref) where the bit-field
(of type `U`) is mutable but `fieldtypes(T)` remains immutable.

See also:
	[`ImmutablePackedInstances`](@ref)

"""
mutable struct MutablePackedInstances{
	U <: Unsigned, T <: Tuple
	} <: AbstractPackedInstances{U, T}

	bits::U

	@inline function MutablePackedInstances(
		source::_DataContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

	# This is strictly unnecessary but alleviates `@generated` equivalent.
	@inline function MutablePackedInstances(
		source::AbstractPackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

end

"""

	MutablePackedInstances(
		::Type{<: Unsigned}[, values...]
		)

Constructs a new `MutablePackedInstances` from the provided argument(s),
densely encoding the content in the accompanying unsigned type.

!!! note "Multiplicity"
	Given that only one `instances` value can be stored for each individual
	type, the last encountered such value is selected.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = MutablePackedInstances(UInt8, air);

julia> ismutable(bit_pack)
true
```

"""
@inline function MutablePackedInstances(
	::Type{U}, values...
	) where {U <: Unsigned}

	@inline return MutablePackedInstances(_DataContainer(U, values...))

end

"""

	MutablePackedInstances(
		::AbstractPackedInstances[, values...]
		)

Constructs a new `MutablePackedInstances` from the provided argument(s),
augmenting new content and overwriting existing content if so requested.

!!! note "Multiplicity"
	Given that only one `instances` value can be stored for each individual
	type, the last encountered such value is selected.

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> using BitPackedInstances

julia> bit_pack = MutablePackedInstances(UInt8, east);

julia> bit_pack = MutablePackedInstances(bit_pack, alpha);

julia> match_content(bit_pack, east, alpha)
true

julia> bit_pack = MutablePackedInstances(bit_pack, red);

julia> match_content(bit_pack, east, red)
true
```

"""
@inline function MutablePackedInstances(
	bit_pack::AbstractPackedInstances, values...
	)

	@inline return MutablePackedInstances(_DataContainer(bit_pack, values...))

end

"""

	MutablePackedInstances(
		::Type{<: Unsigned}, ::AbstractPackedInstances
		)

Constructs a new `MutablePackedInstances` from the provided argument(s),
modifying the underlying unsigned type encoding the content.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = MutablePackedInstances(UInt8, air);

julia> encoding_type(bit_pack)
UInt8

julia> bit_pack = MutablePackedInstances(UInt32, bit_pack);

julia> encoding_type(bit_pack)
UInt32
```

"""
@inline function MutablePackedInstances(
	::Type{U_new}, bit_pack::AbstractPackedInstances
	) where {U_new <: Unsigned}

	@inline return MutablePackedInstances(_DataContainer(U_new, bit_pack))

end

#===============================================================================
INTERNAL
===============================================================================#

@inline function query_constructor(
	::Union{
		MutablePackedInstances,
		Type{<: MutablePackedInstances}
		}
	)

	return MutablePackedInstances

end

@inline function query_name(
	::Union{
		MutablePackedInstances,
		Type{<: MutablePackedInstances}
		}
	)

	return "MutablePackedInstances"

end

#==============================================================================#
