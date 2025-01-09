using TestItemRunner

@testitem "test" begin
    @test true
end

@testitem "basic_menu" begin
    using TestItemMenu: basic_test_menu
    basic_test_menu(".."; verbose=false, menutype="test")
    @test true
end

@run_package_tests
