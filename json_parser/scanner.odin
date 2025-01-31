package json_parser

import "core:strings"
import "core:fmt"
import "core:unicode/utf8"
import "core:unicode"

Token_Type :: enum {
    Left_Bracket,
    Right_Bracket,
    Left_Brace,
    Right_Brace,
    Colon,
    Comma,
    String,
    Int,
    Float,
    Boolean,
    Null,
    End,
}

Token_Value :: union {
    string,
    int,
    f32,
    bool
}

Token :: struct {
    type: Token_Type,
    value: Token_Value,
}

Scanner :: struct {
    source: string,
    start: int,
    tokens: [dynamic]Token,
    current: int,
    line: int,
}

init_scanner :: proc(source: string) -> Scanner {
    scanner := Scanner {
        source = source,
        line = 1,
    }
    return scanner
}

scan :: proc(scanner: ^Scanner) -> [dynamic]Token {
    for !is_at_end(scanner) {
        scanner.start = scanner.current
        scan_token(scanner)
    }

    append(&scanner.tokens, Token {
        type = .End,
    })
    return scanner.tokens
}

is_at_end :: proc(scanner: ^Scanner) -> bool {
    return scanner.current >= len(scanner.source)
}

scan_token :: proc(scanner: ^Scanner) {
    c := advance(scanner)
    switch c {
        case '{':
            append(&scanner.tokens, Token {
                type = .Left_Bracket,
                value = "{"
            })
        case '}':
            append(&scanner.tokens, Token {
                type = .Right_Bracket,
                value = "}",
            })
        case '[':
            append(&scanner.tokens, Token {
                type = .Left_Brace,
                value = "[",
            })
        case ']':
            append(&scanner.tokens, Token {
                type = .Right_Brace,
                value = "]",
            })
        case ',':
            append(&scanner.tokens, Token {
                type = .Comma,
                value = ",",
            })
        case ':':
            append(&scanner.tokens, Token {
                type = .Colon,
                value = ":",
            })
        case '\n':
            scanner.line += 1
        case ' ': // Do nothing on whitespace
        case '"':
            add_string(scanner)
        case '-':
            if unicode.is_digit(peek(scanner)) {
                advance(scanner)
                add_number(scanner)
            }
        case:
            if unicode.is_digit(c) {
                add_number(scanner)
            } else if unicode.is_alpha(c) {
                add_keyword(scanner)
            } else {
                fmt.println("Unexpected Token")
            }
    }
}

advance :: proc(scanner: ^Scanner) -> rune {
    // This is weird but this is the only way I know how to get the full rune from just an index
    for r in scanner.source[scanner.current:] {
        scanner.current += utf8.rune_size(r)
        return r
    }
    fmt.println("🚨 Something went wrong 🚨")
    return '🚨'
}

add_string :: proc(scanner: ^Scanner) {
    for peek(scanner) != '"' && !is_at_end(scanner) {
        advance(scanner)
    }

    if is_at_end(scanner) {
        fmt.println("Unterminated String")
    }

    advance(scanner)

    append(&scanner.tokens, Token {
        type = .String,
        value = scanner.source[scanner.start + 1 : scanner.current - 1]
    })
}

add_number :: proc(scanner: ^Scanner) {
    for unicode.is_digit(peek(scanner)) {
        advance(scanner)
    }

    if peek(scanner) == '.' {
        if (!unicode.is_digit(peek_next(scanner))) {
            fmt.println("Expected digit after . (trying to parse float)")
            //error
        }
        advance(scanner)

        for unicode.is_digit(peek(scanner)) {
            advance(scanner)
        }

        append(&scanner.tokens, Token {
            type = .Float,
            // idk how to cast strings to numbers in Odin
            // value = f32(scanner.source[scanner.start : scanner.current])
            value = scanner.source[scanner.start : scanner.current]
        })
    } else {
        append(&scanner.tokens, Token {
            type = .Int,
            // value = int(scanner.source[scanner.start : scanner.current])
            value = scanner.source[scanner.start : scanner.current]
        })
    }
}

add_keyword :: proc(scanner: ^Scanner) {
    for unicode.is_alpha(peek(scanner)) {
        advance(scanner)
    }

    keyword := scanner.source[scanner.start : scanner.current]
    switch keyword {
        case "true":
            append(&scanner.tokens, Token {
                type = .Boolean,
                value = true,
            })
        case "false":
            append(&scanner.tokens, Token {
                type = .Boolean,
                value = false,
            })
        case "null":
            append(&scanner.tokens, Token {
                type = .Null,
            })
        case:
            fmt.println("Unexpected Token")
    }
}

peek :: proc(scanner: ^Scanner) -> rune {
    if is_at_end(scanner) {
        return '!'
    }

    // Similar to advance proc, this is my hack
    for r in scanner.source[scanner.current:] {
        return r
    }
    fmt.println("🚨 Something went wrong 🚨")
    return '!'
}

peek_next :: proc(scanner: ^Scanner) -> rune {
    if is_at_end(scanner) {
        return '!'
    }

    // Still gross
    for r, i in scanner.source[scanner.current:] {
        if (i > 0) {
            return r
        }
    }
    return '!'
}
