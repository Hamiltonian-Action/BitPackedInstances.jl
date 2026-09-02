#!/usr/bin/env julia
#==============================================================================#

# Satisfy own dependencies when executed as a script.
if abspath(PROGRAM_FILE) == @__FILE__
	import Pkg
	Pkg.activate(@__DIR__)
	Pkg.instantiate()
end

using TestItemRunner

include("argument_parsing/query.jl")

function main(
	arguments::Base.AbstractVecOrTuple
	)

	enabled_tags = query_enabled_tags(arguments)
	@run_package_tests filter = item -> all(in(enabled_tags), item.tags)
	return nothing

end

# Either executed as a script or invoked through package test procedure.
if abspath(PROGRAM_FILE) == @__FILE__
	main(ARGS)
else
	# Disable static analysis by default.
	# TODO: Revisit once JET ceases being a problem on nightly builds.
	main(isempty(ARGS) ? ["disable", "--static_analysis"] : ARGS)
end

#==============================================================================#
