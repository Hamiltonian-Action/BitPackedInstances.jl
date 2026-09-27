
#==============================================================================#

"""

	ImmutablePackedInstances{U <: Unsigned, T <: Tuple}

Concrete instantiation of [`AbstractPackedInstances`](@ref) where both the
bit-field (of type `U`) and `fieldtypes(T)` are immutable.

See also:
	[`MutablePackedInstances`](@ref)

"""
struct ImmutablePackedInstances{
	U <: Unsigned, T <: Tuple
	} <: AbstractPackedInstances{U, T}

	bits::U

	@inline function ImmutablePackedInstances(
		source::_DataContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

	# This is strictly unnecessary but alleviates `@generated` equivalent.
	@inline function ImmutablePackedInstances(
		source::AbstractPackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

end

"""

	ImmutablePackedInstances(
		::Type{<: Unsigned}[, values...]
		)

Constructs a new `ImmutablePackedInstances` from the provided argument(s),
densely encoding the content in the accompanying unsigned type.

!!! note "Multiplicity"
	Given that only one `instances` value can be stored for each individual
	type, the last encountered such value is selected.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8, air);

julia> ismutable(bit_pack)
false
```

"""
@inline function ImmutablePackedInstances(
	::Type{U}, values...
	) where {U <: Unsigned}

	@inline return ImmutablePackedInstances(_DataContainer(U, values...))

end

"""

	ImmutablePackedInstances(
		::AbstractPackedInstances[, values...]
		)

Constructs a new `ImmutablePackedInstances` from the provided argument(s),
augmenting new content and overwriting existing content if so requested.

!!! note "Multiplicity"
	Given that only one `instances` value can be stored for each individual
	type, the last encountered such value is selected.

# Examples

```jldoctest
julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8, east);

julia> bit_pack = ImmutablePackedInstances(bit_pack, alpha);

julia> match_content(bit_pack, east, alpha)
true

julia> bit_pack = ImmutablePackedInstances(bit_pack, red);

julia> match_content(bit_pack, east, red)
true
```

"""
@inline function ImmutablePackedInstances(
	bit_pack::AbstractPackedInstances, values...
	)

	@inline return ImmutablePackedInstances(_DataContainer(bit_pack, values...))

end

"""

	ImmutablePackedInstances(
		::Type{<: Unsigned}, ::AbstractPackedInstances
		)

Constructs a new `ImmutablePackedInstances` from the provided argument(s),
modifying the underlying unsigned type encoding the content.

# Examples

```jldoctest
julia> @enum Elements begin water; earth; fire; air; end

julia> using BitPackedInstances

julia> bit_pack = ImmutablePackedInstances(UInt8, air);

julia> encoding_type(bit_pack)
UInt8

julia> bit_pack = ImmutablePackedInstances(UInt32, bit_pack);

julia> encoding_type(bit_pack)
UInt32
```

"""
@inline function ImmutablePackedInstances(
	::Type{U_new}, bit_pack::AbstractPackedInstances
	) where {U_new <: Unsigned}

	@inline return ImmutablePackedInstances(_DataContainer(U_new, bit_pack))

end

#===============================================================================
INTERNAL
===============================================================================#

@inline function query_constructor(
	::Union{
		ImmutablePackedInstances,
		Type{<: ImmutablePackedInstances}
		}
	)

	return ImmutablePackedInstances

end

@inline function query_name(
	::Union{
		ImmutablePackedInstances,
		Type{<: ImmutablePackedInstances}
		}
	)

	return "ImmutablePackedInstances"

end

#==============================================================================#
