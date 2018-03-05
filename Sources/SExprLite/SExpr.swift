
public enum SExprAtom: Hashable {
    case `nil`
    case bool(Bool)
    case string(String)
    case symbol(String)
    case integer(Int)
    case float(Float)
}

extension SExprAtom: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .integer(integerLiteral)
    }
}

extension SExprAtom: ExpressibleByFloatLiteral {
    public init(floatLiteral: Float) {
        self = .float(floatLiteral)
    }
}

extension SExprAtom: ExpressibleByBooleanLiteral {
    public init(booleanLiteral: Bool) {
        self = .bool(booleanLiteral)
    }
}

extension SExprAtom: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .`nil`
    }
}

extension SExprAtom: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        self = .string(stringLiteral)
    }
}

public enum SExpr: Equatable {
    case atom(SExprAtom)
    case list([SExpr])

    var isNil: Bool {
        switch self {
        case .atom(let atom) where atom == .`nil`: return true
        default: return false
        }
    }

    var atom: SExprAtom? {
        switch self {
        case .atom(let atom): return atom
        default: return nil
        }
    }

    var list: [SExpr]? {
        switch self {
        case .list(let list): return list
        default: return nil
        }
    }

    /// Maps the content of the expression. If the expression is an atom, it
    /// maps the only value into a single item list. If the expression is a
    /// list, then it maps each element of the list.
    ///
    func map<T>(transform: (SExpr) -> T) -> [T] {
        switch self {
        case .atom:
            return [transform(self)]
        case let .list(list):
            return list.map(transform)
        }
    }
}

extension SExpr: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .atom(.integer(integerLiteral))
    }
}

extension SExpr: ExpressibleByFloatLiteral {
    public init(floatLiteral: Float) {
        self = .atom(.float(floatLiteral))
    }
}

extension SExpr: ExpressibleByBooleanLiteral {
    public init(booleanLiteral: Bool) {
        self = .atom(.bool(booleanLiteral))
    }
}

extension SExpr: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .atom(.`nil`)
    }
}

extension SExpr: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        self = .atom(.string(stringLiteral))
    }
}

extension SExpr: ExpressibleByArrayLiteral {
    public init(arrayLiteral: SExpr...) {
        self = .list(arrayLiteral)
    }
}

let s: SExpr = 4
let ss: [SExpr] = [1, 2, 3]
let ssa: SExpr = [1, 2, 3, "foo", [1, 2]]
