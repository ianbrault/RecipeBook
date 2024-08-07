//
//  Quantity.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/24.
//

import Foundation

enum Quantity: Codable & Equatable & Hashable {

    struct Fraction: Codable & Equatable & Hashable {
        let dividend: Int
        let divisor: Int

        init(_ dividend: Int, _ divisor: Int) {
            self.dividend = dividend
            self.divisor = divisor
        }

        func asFloat() -> CGFloat {
            return CGFloat(integerLiteral: self.dividend) / CGFloat(integerLiteral: self.divisor)
        }

        static func gcd(_ x: Int, _ y: Int) -> Int {
            var a = 0
            var b = max(x, y)
            var r = min(x, y)

            while r != 0 {
                a = b
                b = r
                r = a % b
            }
            return b
        }

        static func lcm(_ x: Int, _ y: Int) -> Int {
            return x / gcd(x, y) * y
        }

        static func +(lhs: Fraction, rhs: Fraction) -> Fraction {
            let lcm = Fraction.lcm(lhs.divisor, rhs.divisor)
            return Fraction(((lcm / lhs.divisor) * lhs.dividend) + ((lcm / rhs.divisor) * rhs.dividend), lcm)
        }
    }

    case none
    case integer(Int)
    case float(CGFloat)
    case fraction(Fraction)

    // contains leading spaces in case no separation is present i.e. "1½"
    private static let unicodeReplacements: [String: String] = [
        "¼": " 1/4",
        "½": " 1/2",
        "¾": " 3/4",
        "⅒": " 1/10",
        "⅓": " 1/3",
        "⅔": " 2/3",
        "⅕": " 1/5",
        "⅖": " 2/5",
        "⅗": " 3/5",
        "⅘": " 4/5",
        "⅙": " 1/6",
        "⅚": " 5/6",
        "⅛": " 1/8",
        "⅜": " 3/8",
        "⅝": " 5/8",
        "⅞": " 7/8",
    ]
    // NOTE: upper 16-bits are the dividend and lower 16-bits are the divisor
    // this is a workaround for Swift not allowing hashable tuples
    private static let unicodeSubstitutions: [Int: String] = [
        (1 << 16) | 4: "¼",
        (1 << 16) | 2: "½",
        (3 << 16) | 4: "¾",
        (1 << 16) | 10: "⅒",
        (1 << 16) | 3: "⅓",
        (2 << 16) | 3: "⅔",
        (1 << 16) | 5: "⅕",
        (2 << 16) | 5: "⅖",
        (3 << 16) | 5: "⅗",
        (4 << 16) | 5: "⅘",
        (1 << 16) | 6: "⅙",
        (5 << 16) | 6: "⅚",
        (1 << 16) | 8: "⅛",
        (3 << 16) | 8: "⅜",
        (5 << 16) | 8: "⅝",
        (7 << 16) | 8: "⅞",
    ]

    func asFloat() -> CGFloat {
        switch self {
        case .none:
            return 0.0
        case .integer(let i):
            return CGFloat(integerLiteral: i)
        case .float(let f):
            return f
        case .fraction(let f):
            return f.asFloat()
        }
    }

    func toString() -> String {
        switch self {
        case .none:
            return ""
        case .integer(let i):
            return String(i)
        case .float(let f):
            return String(NSString(format: "%.1f", f))
        case .fraction(let f):
            var s = ""
            var dividend = f.dividend
            if dividend > f.divisor {
                s += "\(dividend / f.divisor) "
                dividend = dividend % f.divisor
            }
            // check for unicode fraction substitution
            // NOTE: upper 16-bits are the dividend and lower 16-bits are the divisor
            // this is a workaround for Swift not allowing hashable tuples
            if let fraction = Quantity.unicodeSubstitutions[(dividend << 16) | f.divisor] {
                return s + fraction
            } else {
                return s + "\(dividend)/\(f.divisor)"
            }
        }
    }

    static func from(string: String) -> Quantity {
        var string = string.trim()
        // pre-processing: replace any unicode fractions to simplify parsing
        for (unicodeFraction, replacement) in Quantity.unicodeReplacements {
            string = string.replacingOccurrences(of: unicodeFraction, with: replacement)
        }
        string = string.trim()

        if let _ = string.wholeMatch(of: /\d+/) {
            return .integer(Int(string)!)
        } else if let _ = string.wholeMatch(of: /\d?\.\d+/) {
            let number = NumberFormatter().number(from: string)!
            return .float(CGFloat(truncating: number))
        } else if let match = string.wholeMatch(of: /(\d+)\/(\d+)/) {
            let dividend = Int(match.1)!
            let divisor = Int(match.2)!
            return .fraction(Fraction(dividend, divisor))
        } else if let match = string.wholeMatch(of: /(\d+)\s+(\d+)\/(\d+)/) {
            let integer = Int(match.1)!
            let dividend = Int(match.2)!
            let divisor = Int(match.3)!
            return .fraction(Fraction((integer * divisor) + dividend, divisor))
        } else {
            return .none
        }
    }

    static func simplify(fraction: Fraction) -> Quantity {
        // first check if the fraction can be simplified to an integer
        if fraction.dividend % fraction.divisor == 0 {
            return .integer(fraction.dividend / fraction.divisor)
        }
        // otherwise check if the dividend/divisor have a common factor
        let gcd = Fraction.gcd(fraction.dividend, fraction.divisor)
        if gcd != 1 {
            return .fraction(Fraction(fraction.dividend / gcd, fraction.divisor / gcd))
        } else {
            return .fraction(fraction)
        }
    }

    static func +(lhs: Quantity, rhs: Quantity) -> Quantity {
        switch (lhs, rhs) {
        case (.none, .none):
            return .none
        case (.none, _):
            return rhs
        case (_, .none):
            return lhs
        case (.integer(let i), .integer(let ii)):
            return .integer(i + ii)
        case (.float(let f), .float(let ff)):
            return .float(f + ff)
        case (.fraction(let f), .fraction(let ff)):
            return Quantity.simplify(fraction: f + ff)
        case (.integer(let i), .float(let f)), (.float(let f), .integer(let i)):
            return .float(i.toFloat() + f)
        case (.integer(let i), .fraction(let f)), (.fraction(let f), .integer(let i)):
            let newFraction = Fraction(f.dividend + (i * f.divisor), f.divisor)
            return Quantity.simplify(fraction: newFraction)
        case (.float(let f), .fraction(let ff)), (.fraction(let ff), .float(let f)):
            return .float(f + ff.asFloat())
        }
    }

    static func *(lhs: Quantity, rhs: Int) -> Quantity {
        switch lhs {
        case .none:
            return .none
        case .integer(let i):
            return .integer(i * rhs)
        case .float(let f):
            return .float(f * rhs.toFloat())
        case .fraction(let f):
            let newFraction = Fraction(f.dividend * rhs, f.divisor)
            return Quantity.simplify(fraction: newFraction)
        }
    }

    static func *(lhs: Quantity, rhs: CGFloat) -> Quantity {
        switch lhs {
        case .none:
            return .none
        case .integer(let i):
            return .float(i.toFloat() * rhs)
        case .float(let f):
            return .float(f * rhs)
        case .fraction(let f):
            return .float(f.asFloat() * rhs)
        }
    }

    static func /(lhs: Quantity, rhs: Int) -> Quantity {
        switch lhs {
        case .none:
            return .none
        case .integer(let i):
            if i % rhs == 0 {
                return .integer(i / rhs)
            } else {
                return .float(i.toFloat() / rhs.toFloat())
            }
        case .float(let f):
            return .float(f / rhs.toFloat())
        case .fraction(let f):
            let newFraction = Fraction(f.dividend, f.divisor * rhs)
            return Quantity.simplify(fraction: newFraction)
        }
    }

    static func /(lhs: Quantity, rhs: CGFloat) -> Quantity {
        switch lhs {
        case .none:
            return .none
        case .integer(let i):
            return .float(i.toFloat() / rhs)
        case .float(let f):
            return .float(f / rhs)
        case .fraction(let f):
            return .float(f.asFloat() / rhs)
        }
    }
}
