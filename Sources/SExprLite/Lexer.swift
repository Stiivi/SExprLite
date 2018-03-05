// Simple SExpression Lexer
//

import Foundation

//
// Character sets
//
// Whitespace: space, new line, tab, comma
let WhitespaceCharacterSet = CharacterSet.whitespaces | CharacterSet.newlines | ","
let NewLineCharacterSet = CharacterSet.newlines
let DecimalDigitCharacterSet = CharacterSet.decimalDigits
var SymbolStart = CharacterSet.letters | ".*+!-_?$%&=<>./"
var SymbolCharacters = SymbolStart | CharacterSet.decimalDigits | "/#"

public enum TokenType: Equatable {
    case empty
    case error(String)
    case string
    case symbol
    case integer
    case float
    case blockStart
    case blockEnd
}

/// Line and column text position. Starts at line 1 and column 1.
public struct TextPosition: CustomStringConvertible {
    var line: Int = 1
    var column: Int = 1

	/// Advances the text position. If the character is a new line character,
	/// then line position is increased and column position is reset to 1. 
    mutating func advance(with char: UnicodeScalar?) {
		if let char = char {
			if NewLineCharacterSet.contains(char) {
				self.column = 1
				self.line += 1
			}
            self.column += 1
		}
    }

    public var description: String {
        return "\(self.line):\(self.column)"
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
        case .string: str = "\"\(self.text)\""
        case .error(let message): str = "Error: \(message) around '\(self.text)'"
        default:
            str = text
        }
        return "\(str) (\(type)) at \(position)"
    }
    public var debugDescription: String {
        return description
    }
}

public func ==(token: Token, type: TokenType) -> Bool {
    return token.type == type
}

public func ==(left: Token, right: String) -> Bool {
    return left.text == right
}


/// Simple lexer that produces symbols, keywords, integers, operators and
/// docstrings. Symbols can be quoted with a back-quote character.
///
public class Lexer {
	typealias Index = String.UnicodeScalarView.Index

    var iterator: String.UnicodeScalarView.Iterator
    var currentChar: UnicodeScalar? = nil
    var text: String

    public var position: TextPosition
    public var currentToken: Token?

    /// Initialize the lexer with model source.
    ///
    /// - Parameter source: source string
    ///
    public init(_ source:String) {
        iterator = source.unicodeScalars.makeIterator()

        currentChar = iterator.next()
        position = TextPosition()
        text = ""
        currentToken = nil
    }

    /// Latest error token message.
    ///
    public var error: String? {
        guard let type = currentToken?.type else {
            return nil
        }

        switch type {
        case .error(let message): return message
        default: return nil
        }
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
    func advance(discard: Bool=false) {
        if !atEnd {
            if !discard {
                text.unicodeScalars.append(currentChar!)
            }
            currentChar = iterator.next()
			position.advance(with: currentChar)
        }
    }

    /** Accept characters that are equal to the `char` character */
    fileprivate func accept(character: UnicodeScalar, discard: Bool=false) -> Bool {
        if self.currentChar == character {
            self.advance(discard: discard)
            return true
        }
        else {
            return false
        }
    }

    /// Accept characters from a character set `set`
    ///
    /// - Returns: `true` if at character was accepted, otherwise `false`
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

        while(currentChar != nil) {
            if !(set.contains(currentChar!)) {
                break
            }
            advance()
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

        while(self.currentChar != nil) {
            if set.contains(self.currentChar!) {
                break
            }
            self.advance()
            advanced = true
        }
        return advanced
    }

    func readString() -> TokenType {
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
        return .error("Unexpected end in string")
    }

    func readSymbol() -> TokenType {
        acceptWhile(from: SymbolCharacters)
        return .symbol
    }

    func readNumber(isFloat: Bool = false) -> TokenType {
        var type: TokenType = isFloat ? .float : .integer

        acceptWhile(from: DecimalDigitCharacterSet)

        if accept(character: ".") {
            guard !isFloat else {
                return .error("Unexpected '.' in number")
            }

            type = .float
            // At least one has to be accepted
            guard acceptWhile(from: DecimalDigitCharacterSet) else {
                return .error("Digits expected")
            }
        }

        if accept(character: "e") || accept(character: "E") {
            // We can have: e e+ e- E E+ E-
            _ = accept(character:"+") || accept(character: "-")
            type = .float
            acceptWhile(from: DecimalDigitCharacterSet)
        }

        return type
    }

    ///
    /// Parse next token.
    ///
    /// - Returns: currently parsed SourceToken
    ///
    public func readToken() -> TokenType {
        let result: TokenType

        // Skip whitespace
        while(true){
            // If a ; character is encountered outside of a string, that
            // character and all subsequent characters to the next newline
            // should be ignored.
            if accept(character: ";") {
                acceptUntil(from: NewLineCharacterSet)
            }
            else if !accept(from: WhitespaceCharacterSet) {
                break
            }
        }

        guard !self.atEnd else {
            return .empty
        }

        text = ""

        if accept(character: "\"", discard: true) {
            result = readString()
        }
        else if accept(character: "+") || accept(character:"-") {
            if accept(from: DecimalDigitCharacterSet) {
                result = readNumber()
            }
            else {
                result = readSymbol()
            }
        }
        else if accept(character: ".") {
            if accept(from: DecimalDigitCharacterSet) {
                result = readNumber(isFloat: true)
            }
            else {
                result = readSymbol()
            }
        }
        else if accept(from: SymbolStart) {
            result = readSymbol()
        }
        else if accept(from: DecimalDigitCharacterSet) {
            result = readNumber()
        }
        else if accept(character: "(") {
            result = .blockStart
        }
        else if accept(character: ")") {
            result = .blockEnd
        }
        else{
            let error = self.currentChar.map {
                            "Unexpected character '\($0)'"
                        } ?? "Unexpected end"
            
            result = .error(error)
        }

        return result
    }

    func next() -> Token {
        let type = self.readToken()
        return Token(type, text: text, position: position)
    }

    /// Parse the input and return an array of parsed tokens
    public func parse() -> [Token] {
        var tokens = [Token]()

        loop: while(true) {
            let token = next()
            tokens.append(token)

            switch token.type {
            case .empty, .error:
                break loop
            default:
                break
            }
        }

        return tokens
    }

}

