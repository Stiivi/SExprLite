/// SExpr parser.
///
/// ## White-spaces
///
/// Elements are separated by whitespaces: spaces, tabs, newlines. A comma `,`
/// is also considered a whitespace and is ignored by the reader.
///
/// ## Comments
///
/// Comment starts with a semicolon `;` and ends at the end of the same line.
///
/// ## Special atoms
///
/// Parser recognizes `nil`, `true` and `false` as special atoms.
///
/// ## Numbers
///
/// The parser recognizes integers and floats. The numbers have the following
/// format:
///
/// Integer:
///      99999
///     +99999
///     -99999
/// 
/// Flaot examples:
///
///       .00
///      -.00
///     99.00
///    +99.00
///    -99.00
///     99.00e99
///     99.00E+99
///     99.00E-99
///    
/// ## Symbol
///
/// Symbol can start with a letter or any of the following charcters:
/// `".*+!-_?$%&=<>./"` optionally followed by character from the same set, a
/// digit or one of `"/#"`
///
/// ## String
///
/// String begins with a double quote `"` and ends with a double quote `"`.
/// String might contain newline characters.
///

public class Parser {
    var lexer: Lexer
    var token: Token
    
    static func parse(_ string: String) throws -> SExpr? {
        let parser = try Parser(string)
        return try parser.read()
    }
    /// Creates an SExpr parser from a string.
    ///
    public init(_ string: String) throws {
        lexer = Lexer(string)
        token = try lexer.next()
    }

    func advance() throws {
        token = try lexer.next()
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
            guard token.type == .empty else {
                throw SExprParserError.syntaxError("Unexpected '\(token.text)'")
            }

            result = nil
        }

        return result
    }

    /// Accept an atom (string, number, symbol, ...) from the input.
    ///
    /// - Returns: `SExpr` with the atom or `nil` if no atom can be parsed.
    ///
    func acceptAtom() throws -> SExpr? {
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
            try advance()
            return .atom(atom)
        }
        else {
            return nil
        }
    }

    /// Accept a list `(...)` from the input.
    ///
    /// - Returns: `SExpr` with the list or `nil` if no list can be parsed.
    ///
    func acceptList() throws -> SExpr? {
        guard token.type == .blockStart else {
            return nil
        }
        try advance()

        var result = Array<SExpr>()

        loop: while true {
            if let item = try acceptSExpr() {
                result.append(item)
            }
            else {
                switch token.type {
                case .empty:
                    throw SExprParserError.parseError("Unfinished list - unexpected end. Got: '\(token.text)'")
                case .blockEnd:
                    try advance()
                    break loop
                default:
                    try advance()
                }
            }
        }

        return .list(result)
    }

    func acceptSExpr() throws -> SExpr? {
        if let atom = try acceptAtom() {
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
