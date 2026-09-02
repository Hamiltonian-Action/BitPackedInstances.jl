
#==============================================================================#

@testitem "Static analysis" tags = [
	:static_analysis
	] setup = [
		DependencyManager
		] begin

	DependencyManager.satisfy_dependencies(@__DIR__)

	@testset "Aqua" begin
		import Aqua
		Aqua.test_all(BitPackedInstances)
	end

	@testset "JET" begin
		import JET
		JET.test_package(BitPackedInstances)
	end

end

#==============================================================================#
