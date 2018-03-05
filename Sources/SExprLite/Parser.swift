enum SExprParserError: Error {
    case syntaxError(String)
    case parseError(String)
}

enum ParserResult<T> {
    case success(T)
    case error(SExprParserError)
}

/// SExpr parser.
///
public class Parser {
    var lexer: Lexer
    var token: Token
    
    /// Creates an SExpr parser from a string.
    ///
    public init(_ string: String) {
        lexer = Lexer(string)
        token = lexer.next()
    }

    func advance() {
        token = lexer.next()
    }

    /// Reads next element.
    ///
    /// - Returns: An element or `nil` if there are no more elements.
    ///
    public func read() throws -> SExpr? {
        let result: SExpr?

        if let item = try acceptSExpr() {
            result = item
        }
        else {
            switch token.type {
            case .empty:
                result = nil
            case .error(let message):
                throw SExprParserError.syntaxError(message)
            default:
                throw SExprParserError.syntaxError("Unexpected '\(token.text)'")
            }
        }

        return result
    }

    func acceptAtom() -> SExpr? {
        let atom: SExprAtom?

        switch token.type {
        case .string:
            atom = .string(token.text)
        case .symbol:
            switch token.text {
            case "nil":
                atom = .`nil`
            case "true":
                atom = .bool(true)
            case "false":
                atom = .bool(false)
            default:
                atom = .symbol(token.text)
            }
        case .integer:
            atom = .integer(Int(token.text)!)
        case .float:
            atom = .float(Float(token.text)!)
        default:
            atom = nil
        }

        if let atom = atom {
            advance()
            return .atom(atom)
        }
        else {
            return nil
        }
    }

    func acceptList() throws -> SExpr? {
        guard token.type == .blockStart else {
            return nil
        }

        advance()
        
        var result = Array<SExpr>()

        loop: while true {
            if let item = try acceptSExpr() {
                result.append(item)
            }
            else {
                switch token.type {
                case .empty:
                    throw SExprParserError.parseError("Unfinished list - unexpected end.")
                case .error(let message):
                    throw SExprParserError.syntaxError(message)
                case .blockEnd:
                    advance()
                    break loop
                default:
                    break
                }
            }
        }

        return .list(result)
    }

    func acceptSExpr() throws -> SExpr? {
        if let atom = acceptAtom() {
            return atom
        }
        else if let list = try acceptList() {
            return list
        }
        else {
            return nil
        }
    }

}
