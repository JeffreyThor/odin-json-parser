package main

import "core:fmt"
import "core:os"
import "json_parser"

main :: proc() {
    if data, ok := os.read_entire_file("input.json"); ok {
        scanner := json_parser.init_scanner(string(data))
        tokens := json_parser.scan(&scanner)

        for token in tokens {
            fmt.printfln("Token: Type=%d, Value=%s", token.type, token.value)
        }
    }
}
