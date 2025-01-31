package json_parser

JSON_Value :: union {
    string,
    int,
    f32,
    bool,
    map[string]JSON_Value,
    [dynamic]JSON_Value,
}
