@testset "Fixture integrity" begin
    for row in fixture_rows(joinpath(FIXTURES, "sha256.csv"))
        @test bytes2hex(sha256(read(joinpath(FIXTURES, row["file"])))) == row["sha256"]
    end
end

@testset "Frozen Python and independent R numerical agreement" begin
    comparisons = cross_language_comparisons(FIXTURES)
    for c in comparisons
        @test comparison_passes(c)
    end
    summary = comparison_summary(comparisons)
    @test all(row -> row.passed, summary)
    println("Cross-language comparisons: ", length(comparisons),
            "; max absolute difference: ", maximum(r.max_absolute_difference for r in summary),
            "; max symmetric relative difference: ", maximum(r.max_relative_difference for r in summary))
end
