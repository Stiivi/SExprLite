import XCTest
@testable import SExprLite

class LexerTests: XCTestCase {
    var lexer: Lexer? = nil

    func next() -> Token {
        let result: Token
        do {
            result = try lexer!.next()
        }
        catch {
            XCTFail("Unexpected lexer error: \(error)")
            result = Token(.empty, text: "", position: TextPosition())
        }
        return result
        
    }
    func readToken() -> TokenType {
        let result: TokenType
        do {
            result = try lexer!.readToken()
        }
        catch {
            XCTFail("Unexpected lexer error: \(error)")
            result = .empty
        }
        return result
        
    }

    func testEmpty() {
        lexer = Lexer("")

        let type = readToken()

        XCTAssertEqual(type, .empty)
    }

    func testEmptySpacesComment() {
        lexer = Lexer("  \n; this is a comment")

        let type = readToken()

        XCTAssertEqual(type, .empty)
    }
    func testSymbol() {
        lexer = Lexer("thing")
        var token = next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "thing")

        lexer = Lexer("+")
        token = next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "+")

        lexer = Lexer("+++")
        token = next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "+++")
    
    }
    func testString() {
        lexer = Lexer("\"\"")
        var token = next()

        XCTAssertEqual(token.type, .string)
        XCTAssertEqual(token.text, "")

        lexer = Lexer("\"Hi there!\"")
        token = next()

        XCTAssertEqual(token.type, .string)
        XCTAssertEqual(token.text, "Hi there!")
    
    }

    func testInteger() {
        lexer = Lexer("12345")
        var token = next()

        XCTAssertEqual(token.type, .integer)
        XCTAssertEqual(token.text, "12345")

        lexer = Lexer("0")
        token = next()

        XCTAssertEqual(token.type, .integer)
        XCTAssertEqual(token.text, "0")
    }

    func testFloat() {
        lexer = Lexer("123.456")
        var token = next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, "123.456")

        lexer = Lexer(".123")
        token = next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123")

        lexer = Lexer(".123e+10")
        token = next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123e+10")

        lexer = Lexer(".123E-10")
        token = next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123E-10")
    }

    func testEmptyBlock() {
        lexer = Lexer("()")
        var token = next()

        XCTAssertEqual(token.type, .blockStart)
        token = next()
        XCTAssertEqual(token.type, .blockEnd)
        
    }
    func testBlock() {
        lexer = Lexer("(123)")
        var token = next()

        XCTAssertEqual(token.type, .blockStart)
        token = next()
        XCTAssertEqual(token.text, "123")
        token = next()
        XCTAssertEqual(token.type, .blockEnd)
        
    }
}


class ParserTests: XCTestCase {

    func parse(_ string: String) -> SExpr? {
        let result: SExpr?
        do {
            result = try Parser.parse(string)
        }
        catch {
            XCTFail("Unexpected error: \(error)")
            result = nil
        }
        return result
    }

    func testEmpty() {
        let value = parse("")

        XCTAssertEqual(value, nil)
    }

    func testList() {
        let value = parse("(1 2 3)")

        XCTAssertEqual( value, [1, 2, 3])
    }

    func testNestedList() {
        let value = parse("((1 2 3) (4 5 6) (\"a\", \"b\", \"c\"))")

        XCTAssertEqual( value, [[1, 2, 3], [4, 5, 6], ["a", "b", "c"]])
    }
}
