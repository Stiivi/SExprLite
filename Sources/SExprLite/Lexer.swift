// Simple SExpression Lexer
//

import Foundation

//
// Character sets
//
// Whitespace: space, new line, tab, comma
public enum TokenType: Equatable {
    case empty
    case string
    case symbol
    case integer
    case float
    case blockStart
    case blockEnd
}

/// Line and column text position. Starts at line 1 and column 1.
///
public struct TextPosition: CustomStringConvertible {
    var line: Int = 1
    var column: Int = 1

	/// Advances column position.
    ///
    mutating func advanceColumn() {
        column += 1
    }

    mutating func advanceLine() {
        column = 1
        line += 1
    }
    public var description: String {
        return "\(line):\(column)"
    }
}


public struct Token: CustomStringConvertible, CustomDebugStringConvertible {
    public let type: TokenType
    public let text: String
    public let position: TextPosition

    public init(_ type: TokenType, text: String, position: TextPosition) {
        self.type = type
        self.text = text
        self.position = position
    }

    public var description: String {
        let str: String
        switch type {
        case .empty: str = "(empty)"
        case .string: str = "\"\(text)\""
        default:
            str = text
        }
        return "\(str) (\(type)) at \(position)"
    }
    public var debugDescription: String {
        return description
    }
}


/// Simple lexer that produces symbols, literals and delimiters.
///
public class Lexer {
	typealias Index = String.UnicodeScalarView.Index

    var iterator: String.UnicodeScalarView.Iterator
    var currentChar: UnicodeScalar? = nil
    var text: String

    let whitespaces: CharacterSet
    let decimalDigits: CharacterSet
    var symbolStart: CharacterSet
    var symbolCharacters: CharacterSet

    public var position: TextPosition

    /// Initialize the lexer with model source.
    ///
    /// - Parameter source: source string
    ///
    public init(_ source:String) {
        iterator = source.unicodeScalars.makeIterator()

        currentChar = iterator.next()
        position = TextPosition()
        text = ""

        whitespaces = CharacterSet.whitespaces | CharacterSet.newlines | ","
        decimalDigits = CharacterSet.decimalDigits
        symbolStart = CharacterSet.letters | ".*+!-_?$%&=<>./"
        symbolCharacters = symbolStart | CharacterSet.decimalDigits | "/#"
    }

    /// true` if the parser is at end of input.
    ///
    public var atEnd: Bool {
        return currentChar == nil
    }


    /// Advance to the next character and set current character.
    ///
    /// - Parameter discard: If `true` then the current character is not
    ///                      appended to the result text.
    ///
    func advance(discard: Bool=false) {
        if !atEnd {
            if !discard {
                text.unicodeScalars.append(currentChar!)
            }
            currentChar = iterator.next()

            if let char = currentChar {
                if CharacterSet.newlines.contains(char) {
                    position.advanceLine()
                }
                else {
                    position.advanceColumn()
                }
            }
        }
    }

    /// Accept characters that are equal to the `char` character
    ///
    /// - Returns: `true` if character was accepted, otherwise `false`.
    ///
    fileprivate func accept(character: UnicodeScalar, discard: Bool=false) -> Bool {
        if self.currentChar == character {
            self.advance(discard: discard)
            return true
        }
        else {
            return false
        }
    }

    /// Accept characters from a character set and advance if the character was
    /// accepted..
    ///
    /// - Returns: `true` if character was accepted, otherwise `false`
    ///
    fileprivate func accept(from set: CharacterSet) -> Bool {
        if currentChar.map({ set.contains($0) }) ?? false {
            self.advance()
            return true
        }
        else {
            return false
        }
    }

    /// Accept characters while a character for a set is encountered.
    ///
    /// - Returns: `true` if at least one character was accepted, otherwise
    /// `false`
    ///
    @discardableResult
    private func acceptWhile(from set: CharacterSet) -> Bool {
        var advanced: Bool = false

        while accept(from: set) {
            advanced = true 
        }

        return advanced
    }

    /// Accept characters until a character for a set is encountered.
    ///
    /// - Returns: `true` if at least one character was accepted, otherwise
    /// `false`
    ///
	@discardableResult
    private func acceptUntil(from set: CharacterSet) -> Bool {
        var advanced: Bool = false

        while true {
            if currentChar.map({ set.contains($0) }) ?? true {
                break
            }
            else {
                self.advance()
                advanced = true
            }
        }

        return advanced
    }

    /// Read a string literal
    ///
    func readString() throws -> TokenType {
        // Strings are enclosed in "double quotes". May span multiple
        // lines. 

        while !atEnd {
            // Escape character
            if accept(character: "\"", discard: true){
                return .string
            }
            else if accept(character: "\\") && atEnd {
                // Unexpected end of string - expected escaped character
                break
            }

            advance()
        }

        throw SExprParserError.syntaxError("Unexpected end in string")
    }

    /// Read a symbol
    ///
    func readSymbol() -> TokenType {
        acceptWhile(from: symbolCharacters)
        return .symbol
    }

    /// Read an integer or a float.
    ///
    /// - Parameter isFloat: If `true` then a float that started with `.` is
    /// expected. If `false` then either integer or float might be parsed.
    ///
    func readNumber(isFloat: Bool = false) throws -> TokenType {
        var type: TokenType = isFloat ? .float : .integer

        acceptWhile(from: decimalDigits)

        if accept(character: ".") {
            guard !isFloat else {
                throw SExprParserError.syntaxError("Unexpected '.' in number")
            }

            type = .float
            // At least one has to be accepted
            guard acceptWhile(from: decimalDigits) else {
                throw SExprParserError.syntaxError("Digits expected")
            }
        }

        if accept(character: "e") || accept(character: "E") {
            // We can have: e e+ e- E E+ E-
            _ = accept(character:"+") || accept(character: "-")
            type = .float
            acceptWhile(from: decimalDigits)
        }

        return type
    }

    ///
    /// Parse next token.
    ///
    /// - Returns: currently parsed SourceToken
    ///
    public func readToken() throws -> TokenType {
        let result: TokenType

        // Skip whitespace
        while(true){
            // If a ; character is encountered outside of a string, that
            // character and all subsequent characters to the next newline
            // should be ignored.
            if accept(character: ";") {
                acceptUntil(from: CharacterSet.newlines)
            }
            else if !accept(from: whitespaces) {
                break
            }
        }

        text = ""

        guard !self.atEnd else {
            return .empty
        }

        if accept(character: "\"", discard: true) {
            result = try readString()
        }
        else if accept(character: "+") || accept(character:"-") {
            if accept(from: decimalDigits) {
                result = try readNumber()
            }
            else {
                result = readSymbol()
            }
        }
        else if accept(character: ".") {
            if accept(from: decimalDigits) {
                result = try readNumber(isFloat: true)
            }
            else {
                result = readSymbol()
            }
        }
        else if accept(from: symbolStart) {
            result = readSymbol()
        }
        else if accept(from: decimalDigits) {
            result = try readNumber()
        }
        else if accept(character: "(") {
            result = .blockStart
        }
        else if accept(character: ")") {
            result = .blockEnd
        }
        else{
            let message = self.currentChar.map {
                            "Unexpected character '\($0)'"
                        } ?? "Unexpected end"
            
            throw SExprParserError.syntaxError(message)
        }

        return result
    }

    /// Parse and return next token.
    ///
    func next() throws -> Token {
        let type = try self.readToken()

        return Token(type, text: text, position: position)
    }
}

