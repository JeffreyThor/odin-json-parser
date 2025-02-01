package main

import "core:fmt"
import "core:os"
import "json_parser"

main :: proc() {
    data, ok := os.read_entire_file("input.json")
    if !ok {
        panic("Failed to read input file")
    }

    json := json_parser.parse(string(data))
    fmt.println(json)
}
