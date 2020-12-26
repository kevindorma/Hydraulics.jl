# code for testing our package
using Hydraulics, Test

@testset "moody" begin
    # test case moody
	# from https://neutrium.net/fluid-flow/pressure-loss-from-fittings-3k-method/
	# Reynolds number 306900, e = 0.068 mm, D = 102.3
	eD = 0.068 / 102.3
	Reynolds = 306900.0
    	@test (abs(Hydraulics.calcMoodyF(Reynolds,eD) - 0.018) < 0.001)
end
