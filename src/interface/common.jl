
#==============================================================================#

#===============================================================================
COPY
===============================================================================#

@inline function Base.copy(
	source::Union{
		PackedInstancesKeysIterator,
		Iterators.Reverse{<: PackedInstancesKeysIterator}
		}
	)

	if source isa Iterators.Reverse
		direction = Iterators.reverse
		keys_iterator = source.itr
	else
		direction = identity
		keys_iterator = source
	end
	return direction(PackedInstancesKeysIterator(keys_iterator))

end

@inline function Base.copy(
	source::Union{
		PackedInstancesValuesIterator,
		Iterators.Reverse{<: PackedInstancesValuesIterator}
		}
	)

	if source isa Iterators.Reverse
		direction = Iterators.reverse
		values_iterator = source.itr
	else
		direction = identity
		values_iterator = source
	end
	return direction(PackedInstancesValuesIterator(values_iterator))

end

@inline function Base.copy(
	source::Union{
		AbstractPackedInstances,
		Iterators.Reverse{<: AbstractPackedInstances}
		}
	)

	if source isa Iterators.Reverse
		direction = Iterators.reverse
		bit_pack = source.itr
	else
		direction = identity
		bit_pack = source
	end
	constructor = query_constructor(bit_pack)
	return direction(constructor(bit_pack))

end

#===============================================================================
LENGTH
===============================================================================#

@inline function Base.length(
	::PackedInstancesKeysIterator{T}
	) where {T <: Tuple}

	return length(fieldtypes(T))

end

@inline function Base.length(
	::PackedInstancesValuesIterator{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return length(fieldtypes(T))

end

@inline function Base.length(
	::AbstractPackedInstances{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return length(fieldtypes(T))

end

#===============================================================================
ELTYPE
===============================================================================#

@inline function Base.eltype(
	::Type{PackedInstancesKeysIterator{T}}
	) where {T <: Tuple}

	return eltype(fieldtypes(T))

end

@inline function Base.eltype(
	::Type{<: PackedInstancesValuesIterator{U, T}}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(map(ComposedFunction(first, instances), fieldtypes(T)))

end

@inline function Base.eltype(
	::Type{<: AbstractPackedInstances{U, T}}
	) where {U <: Unsigned, T <: Tuple}

	return Pair{
		keytype(AbstractPackedInstances{U, T}),
		valtype(AbstractPackedInstances{U, T})
		}

end

#===============================================================================
EQUALITY
===============================================================================#

@inline function Base.:(==)(
	left::PackedInstancesKeysIterator,
	right::PackedInstancesKeysIterator
	)

	return length(left) == length(right) &&
		all(splat(==), zip(left, right))

end

@inline function Base.:(==)(
	left::Iterators.Reverse{<: PackedInstancesKeysIterator},
	right::Iterators.Reverse{<: PackedInstancesKeysIterator}
	)

	return length(left.itr) == length(right.itr) &&
		all(splat(==), zip(left.itr, right.itr))

end

@inline function Base.:(==)(
	left::PackedInstancesValuesIterator,
	right::PackedInstancesValuesIterator
	)

	return length(left) == length(right) &&
		all(splat(==), zip(left, right))

end

@inline function Base.:(==)(
	left::Iterators.Reverse{<: PackedInstancesValuesIterator},
	right::Iterators.Reverse{<: PackedInstancesValuesIterator}
	)

	return length(left.itr) == length(right.itr) &&
		all(splat(==), zip(left.itr, right.itr))

end

@inline function Base.:(==)(
	left::MutablePackedInstances{U},
	right::MutablePackedInstances{U}
	) where {U <: Unsigned}

	return values(left) == values(right)

end

@inline function Base.:(==)(
	left::Iterators.Reverse{<: MutablePackedInstances{U}},
	right::Iterators.Reverse{<: MutablePackedInstances{U}}
	) where {U <: Unsigned}

	return values(left.itr) == values(right.itr)

end

@inline function Base.:(==)(
	left::ImmutablePackedInstances{U},
	right::ImmutablePackedInstances{U}
	) where {U <: Unsigned}

	return values(left) == values(right)

end

@inline function Base.:(==)(
	left::Iterators.Reverse{<: ImmutablePackedInstances{U}},
	right::Iterators.Reverse{<: ImmutablePackedInstances{U}}
	) where {U <: Unsigned}

	return values(left.itr) == values(right.itr)

end

#===============================================================================
HASH
===============================================================================#

function Base.hash(
	input::Union{
		PackedInstancesKeysIterator,
		Iterators.Reverse{<: PackedInstancesKeysIterator}
		},
	admixture::UInt
	)

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{PackedInstancesKeysIterator}
		keys_iterator = input.itr
	else
		hashed_type = PackedInstancesKeysIterator
		keys_iterator = input
	end
	output = hash(hashed_type, admixture)
	for key in keys_iterator
		output = hash(key, output)
	end
	return output

end

function Base.hash(
	input::Union{
		PackedInstancesValuesIterator,
		Iterators.Reverse{<: PackedInstancesValuesIterator}
		},
	admixture::UInt
	)

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{PackedInstancesValuesIterator}
		values_iterator = input.itr
	else
		hashed_type = PackedInstancesValuesIterator
		values_iterator = input
	end
	output = hash(hashed_type, admixture)
	for value in values_iterator
		output = hash(value, output)
	end
	return output

end

function Base.hash(
	input::Union{
		MutablePackedInstances{U},
		Iterators.Reverse{<: MutablePackedInstances{U}}
		},
	admixture::UInt
	) where {U <: Unsigned}

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{MutablePackedInstances{U}}
		bit_pack = input.itr
	else
		hashed_type = MutablePackedInstances{U}
		bit_pack = input
	end
	output = hash(hashed_type, admixture)
	for (_, value) in bit_pack
		output = hash(value, output)
	end
	return output

end

function Base.hash(
	input::Union{
		ImmutablePackedInstances{U},
		Iterators.Reverse{<: ImmutablePackedInstances{U}}
		},
	admixture::UInt
	) where {U <: Unsigned}

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{ImmutablePackedInstances{U}}
		bit_pack = input.itr
	else
		hashed_type = ImmutablePackedInstances{U}
		bit_pack = input
	end
	output = hash(hashed_type, admixture)
	for (_, value) in bit_pack
		output = hash(value, output)
	end
	return output

end

#==============================================================================#
