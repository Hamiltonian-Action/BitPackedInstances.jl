
#==============================================================================#

@testitem "Functionality" default_imports = false tags = [
	:functionality
	] setup = [
		DependencyManager
		] begin

	DependencyManager.satisfy_dependencies(@__DIR__)

	include("preamble.jl")

	@testset "Interface" begin
		test_interface(
			unsigned_type, round_count,
			AbstractPackedInstances_types,
			benevolent_types, malevolent_types
			)
	end

	@testset "Progression" begin
		test_progression(
			unsigned_type, AbstractPackedInstances_types, generated_enums
			)
	end

	@testset "Show" begin
		test_show(
			unsigned_type, round_count,
			AbstractPackedInstances_types, benevolent_types
			)
	end

end

#==============================================================================#
