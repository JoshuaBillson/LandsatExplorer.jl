using LandsatExplorer
using Test, Dates
import ArchGDAL
using Pipe: @pipe

const LE = LandsatExplorer

roi = [ 
    [52.1, -114.4], 
    [52.1, -114.1], 
    [51.9, -114.1], 
    [51.9, -114.4], 
    [52.1, -114.4]
]

@testset "LandsatExplorer.jl" begin
    # Test Polygon Search
    polygon = ArchGDAL.createpolygon(roi)
    dates = (DateTime(2020, 8, 1), DateTime(2020, 9, 1))
    scene = search("LANDSAT_8", 2, dates=dates, geom=polygon, clouds=5) |> first
    @test scene.Id == "LC80430232020231LGN00"

    # Test Point Search
    point = Point(52.0, -114.2)
    results_1 = search("LANDSAT_8", 2, dates=dates, geom=point)
    @test all([!isnothing(match(r"LC08_L2SP_04\d024_", x)) for x in results_1.Name])
    @test length(results_1.Name) == 4

    # Test Bounding Box Search
    bb = BoundingBox((52.1, -114.4), (51.9, -114.1))
    results_2 = search("LANDSAT_8", 2, dates=dates, geom=bb)
    @test all([!isnothing(match(r"LC08_L2SP_04[23]02[34]_2020", x)) for x in results_2.Name])
    @test length(results_2.Name) == 6

    # Test Scene and Entity ID
    scene_id = results_2.Name |> first
    entity_id = results_2.Id |> first
    @test !LE.is_entity_id(scene_id)
    @test LE.is_scene_id(scene_id)
    @test LE.is_entity_id(entity_id)
    @test !LE.is_scene_id(entity_id)
    @test get_entity_id(scene_id) == entity_id

    # Guess Dataset
    @test LE.guess_dataset(scene_id) == "landsat_ot_c2_l2"
    @test LE.guess_dataset(entity_id) == "landsat_ot_c2_l1"

    # Get Dataset
    @test LE.get_dataset(5, 1) == "landsat_tm_c2_l1"
    @test LE.get_dataset("LANDSAT_5", 1) == "landsat_tm_c2_l1"
    @test LE.get_dataset(5, 2) == "landsat_tm_c2_l2"
    @test LE.get_dataset("LANDSAT_5", 2) == "landsat_tm_c2_l2"
    @test LE.get_dataset(7, 1) == "landsat_etm_c2_l1"
    @test LE.get_dataset("LANDSAT_7", 1) == "landsat_etm_c2_l1"
    @test LE.get_dataset(7, 2) == "landsat_etm_c2_l2"
    @test LE.get_dataset("LANDSAT_7", 2) == "landsat_etm_c2_l2"
    @test LE.get_dataset(8, 1) == "landsat_ot_c2_l1"
    @test LE.get_dataset("LANDSAT_8", 1) == "landsat_ot_c2_l1"
    @test LE.get_dataset(8, 2) == "landsat_ot_c2_l2"
    @test LE.get_dataset("LANDSAT_8", 2) == "landsat_ot_c2_l2"
    @test LE.get_dataset(9, 1) == "landsat_ot_c2_l1"
    @test LE.get_dataset("LANDSAT_9", 1) == "landsat_ot_c2_l1"
    @test LE.get_dataset(9, 2) == "landsat_ot_c2_l2"
    @test LE.get_dataset("LANDSAT_9", 2) == "landsat_ot_c2_l2"

    # Test Zero Results
    @test_throws ErrorException search("LANDSAT_9", 2, dates=dates, geom=bb)

    # Test Download
    logout()
    scene_to_download = search("LANDSAT_8", 2, dates=dates, geom=point, clouds=6).Name |> first
    downloaded = download_scene(scene_to_download; log_progress=true, unpack=true)
    @test downloaded == joinpath(pwd(), scene_to_download)
    rm(downloaded, recursive=true)
    logout()
end
