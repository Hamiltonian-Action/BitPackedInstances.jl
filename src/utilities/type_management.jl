
#==============================================================================#

# CAUTION: This is slightly unsafe due to potential clashes.
@inline function canonical_form(
	input::Base.AbstractVecOrTuple
	)

	return sort(input; by = objectid)

end

# TODO: There has to be a built-in method that does this.
@inline function unwrap_type(
	::Type{Type{X}}
	) where {X}

	return X

end

# This is marked as `@generated` in order to cache the output.
# Compiles to an aliance for `instances(X)` when `allunique` holds.
@inline @generated function unique_instances(
	X::Type
	)

	# Eliminate Type{X} wrapper.
	X = unwrap_type(X)
	values = tuple(unique(instances(X))...)
	return quote
		return $values
		end

end

#==============================================================================#
