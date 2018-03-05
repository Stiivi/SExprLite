import XCTest
@testable import SExprLite

class LexerTests: XCTestCase {
    func testEmpty() {
        let lexer = Lexer("")

        let type = lexer.readToken()

        XCTAssertEqual(type, .empty)
    }

    func testEmptySpacesComment() {
        let lexer = Lexer("  \n; this is a comment")

        let type = lexer.readToken()

        XCTAssertEqual(type, .empty)
    }
    func testSymbol() {
        var lexer = Lexer("thing")
        var token = lexer.next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "thing")

        lexer = Lexer("+")
        token = lexer.next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "+")

        lexer = Lexer("+++")
        token = lexer.next()

        XCTAssertEqual(token.type, .symbol)
        XCTAssertEqual(token.text, "+++")
    
    }
    func testString() {
        var lexer = Lexer("\"\"")
        var token = lexer.next()

        XCTAssertEqual(token.type, .string)
        XCTAssertEqual(token.text, "")

        lexer = Lexer("\"Hi there!\"")
        token = lexer.next()

        XCTAssertEqual(token.type, .string)
        XCTAssertEqual(token.text, "Hi there!")
    
    }

    func testInteger() {
        var lexer = Lexer("12345")
        var token = lexer.next()

        XCTAssertEqual(token.type, .integer)
        XCTAssertEqual(token.text, "12345")

        lexer = Lexer("0")
        token = lexer.next()

        XCTAssertEqual(token.type, .integer)
        XCTAssertEqual(token.text, "0")
    }

    func testFloat() {
        var lexer = Lexer("123.456")
        var token = lexer.next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, "123.456")

        lexer = Lexer(".123")
        token = lexer.next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123")

        lexer = Lexer(".123e+10")
        token = lexer.next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123e+10")

        lexer = Lexer(".123E-10")
        token = lexer.next()

        XCTAssertEqual(token.type, .float)
        XCTAssertEqual(token.text, ".123E-10")
    }

    func testBlock() {
        var lexer = Lexer("(123)")
        var token = lexer.next()

        XCTAssertEqual(token.type, .blockStart)
        token = lexer.next()
        XCTAssertEqual(token.text, "123")
        token = lexer.next()
        XCTAssertEqual(token.type, .blockEnd)
        
    }
}


class ParserTests: XCTestCase {

    func read(_ parser: Parser) -> SExpr? {
        let result: SExpr?
        do {
            result = try parser.read()
        }
        catch {
            XCTFail("Unexpected error: \(error)")
            result = nil
        }
        return result
    }

    func testEmpty() {
        let parser = Parser("")
        let value = read(parser)

        XCTAssertEqual(value, nil)
    }

    func testList() {
        let parser = Parser("(1 2 3)")
        let value = read(parser)

        XCTAssertEqual( value, [1, 2, 3])
    }

    func testNestedList() {
        let parser = Parser("((1 2 3) (4 5 6) (\"a\", \"b\", \"c\"))")
        let value = read(parser)

        XCTAssertEqual( value, [[1, 2, 3], [4, 5, 6], ["a", "b", "c"]])
    }
}
