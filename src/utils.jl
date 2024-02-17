"""Returns true if string matches format for scene id"""
function is_scene_id(id)
    return length(id) == 40 && first(id) == 'L'
end

"""Returns true if string matches format for entity id"""
function is_entity_id(id)
    return length(id) == 21 && first(id) == 'L'
end

"""Parse metadata from Landsat scene ID"""
function parse_scene_id(scene_id)
    elements = split(scene_id, "_")
    return Dict(
        "product_id" => scene_id,
        "sensor" => elements[1][2],
        "satellite" => parse(Int, elements[1][3:4]),
        "processing_level" => parse(Int, elements[2][2]),
        "satellite_orbits" => elements[3],
        "acquisition_date" => elements[4],
        "processing_date" => elements[5],
        "collection_number" => elements[6],
        "collection_category" => elements[7],
    )
end

"""Parse metadata from Landsat entity ID"""
function parse_entity_id(entity_id)
    return Dict(
        "entity_id" => entity_id,
        "sensor" => entity_id[2],
        "satellite" => parse(Int, entity_id[3]),
        "path" => entity_id[4:6],
        "row" => entity_id[7:9],
        "year" => entity_id[10:13],
        "julian_day" => entity_id[14:16],
        "ground_station" => entity_id[17:19],
        "archive_version" => entity_id[20:21],
    )
end

"""Return the dataset string for the provided satellite and processing level"""
function get_dataset(satellite, level)
    sensor = @match satellite begin
        "LANDSAT_5" || 5 => "tm"
        "LANDSAT_7" || 7 => "etm"
        "LANDSAT_8" || "LANDSAT_9" || 8 || 9 => "ot"
        _ => throw(ArgumentError("Unsuported Satellite!"))
    end

    return "landsat_$(sensor)_c2_l$level"
end

"""Return the data id to download a scene belonging to the given dataset"""
function get_data_id(dataset)
    products = Dict(
        "landsat_tm_c2_l1"=>["5e81f14f92acf9ef", "5e83d0a0f94d7d8d", "63231219fdd8c4e5"],
        "landsat_etm_c2_l1"=>[ "5e83d0d0d2aaa488", "5e83d0d08fec8a66"],
        "landsat_ot_c2_l1"=>["632211e26883b1f7", "5e81f14ff4f9941c", "5e81f14f92acf9ef"],
        "landsat_tm_c2_l2"=>["5e83d11933473426", "5e83d11933473426", "632312ba6c0988ef"],
        "landsat_etm_c2_l2"=>["5e83d12aada2e3c5", "5e83d12aed0efa58", "632311068b0935a8"],
        "landsat_ot_c2_l2"=>["5e83d14f30ea90a9", "5e83d14fec7cae84", "632210d4770592cf"]
    )

    return products[dataset]
end

"""Guess the dataset string for the given identifier"""
function guess_dataset(identifier)
    if is_scene_id(identifier)
        metadata = parse_scene_id(identifier)
        satellite = metadata["satellite"]
        level = metadata["processing_level"]
        return get_dataset(satellite, level)
    elseif is_entity_id(identifier)
        metadata = parse_entity_id(identifier)
        satellite = metadata["satellite"]
        return get_dataset(satellite, 1)
    else
        throw(ArgumentError("Identifier does not match specification!"))
    end
end