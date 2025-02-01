package json_parser

import "core:fmt"
import "core:strconv"

JSON_Value :: union {
    string,
    i64,
    f64,
    bool,
    JSON_Object,
    JSON_Array,
}
JSON_Object :: map[string]JSON_Value
JSON_Array :: [dynamic]JSON_Value

Parser :: struct {
    tokens: [dynamic]Token,
    current: int
}

parse :: proc(input: string) -> JSON_Value {
    scanner := init_scanner(input)
    tokens := scan(&scanner)
    parser := init_parser(tokens)
    token := advance(&parser)
    return parse_from_token(&parser, token)
}

init_parser :: proc(tokens: [dynamic]Token) -> Parser {
    return Parser {
        tokens = tokens
    }
}

parse_from_token :: proc(parser: ^Parser, token: Token) -> JSON_Value {
    #partial switch token.type {
    case .String:
        return token.value
    case .Int:
        if value, ok := strconv.parse_i64(token.value); ok {
            return value
        } else {
            fmt.println("Failed to parse int")
            //error
            return {}
        }
    case .Float:
        if value, ok := strconv.parse_f64(token.value); ok {
            return value
        } else {
            fmt.println("Failed to parse float")
            //error
            return {}
        }
    case .Boolean:
        if value, ok := strconv.parse_bool(token.value); ok {
            return value
        } else {
            fmt.println("Failed to parse bool")
            //error
            return {}
        }
    case .Null:
        return nil
    case .Left_Brace:
        return parse_object(parser)
    case .Left_Bracket:
        return parse_array(parser)
    case:
        fmt.println("Unexpected Token")
        return {}
    }
}

parse_object :: proc(parser: ^Parser) -> JSON_Object {
    json_object: JSON_Object

    key_token := advance(parser)
    for key_token.type != .Right_Brace {
        if key_token.type == .End {
            fmt.println("Unterminated JSON Object")
        }

        if key_token.type != .String {
            fmt.println("JSON object fields must begin with a 'key'")
        }

        consume(parser, .Colon)

        value_token := advance(parser)
        json_object[key_token.value] = parse_from_token(parser, value_token)

        consume_comma_unless(parser, .Right_Brace)
        key_token = advance(parser)
    }

    return json_object
}

parse_array :: proc(parser: ^Parser) -> JSON_Array {
    json_array: JSON_Array

    token := advance(parser)
    for token.type != .Right_Bracket {
        if token.type == .End {
            fmt.println("Unterminated JSON Array")
        }
        append(&json_array, parse_from_token(parser, token))

        consume_comma_unless(parser, .Right_Bracket)
        token = advance(parser)
    }

    return json_array
}

@(private="file")
advance :: proc(parser: ^Parser) -> Token {
    token := parser.tokens[parser.current]
    parser.current += 1
    return token
}

@(private="file")
consume :: proc(parser: ^Parser, token_type: Token_Type) {
    if peek(parser).type != token_type {
        //error
    }
    parser.current += 1
}

@(private="file")
consume_comma_unless :: proc(parser: ^Parser, exception: Token_Type) {
    if peek(parser).type == .Comma {
        advance(parser)
        return
    }

    if peek(parser).type != exception {
        //error
    }
}

@(private="file")
peek :: proc(parser: ^Parser) -> Token {
    return parser.tokens[parser.current]
}
