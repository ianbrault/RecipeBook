//
//  IngredientParserTests.swift
//  RecipeBookTests
//
//  Created by Ian Brault on 3/22/24.
//

import XCTest

final class IngredientParserTests: XCTestCase {

    func testGroceryNoQuantity() throws {
        var output: Ingredient

        output = IngredientParser.shared.parse(string: "Eggs")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "Eggs")

        output = IngredientParser.shared.parse(string: " All-purpose  flour")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "All-purpose flour")

        output = IngredientParser.shared.parse(string: "Paper towels ")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "Paper towels")
    }

    func testGroceryBasicQuantity() throws {
        var output: Ingredient

        output = IngredientParser.shared.parse(string: "2 apples")
        XCTAssertEqual(output.quantity, .integer(2))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "apples")

        output = IngredientParser.shared.parse(string: "12  brown-butter chocolate chip cookies")
        XCTAssertEqual(output.quantity, .integer(12))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "brown-butter chocolate chip cookies")
    }

    func testGroceryDecimalQuantity() throws {
        var output: Ingredient

        output = IngredientParser.shared.parse(string: "1.5 lb. Alaskan salmon")
        XCTAssertEqual(output.quantity, .float(1.5))
        XCTAssertEqual(output.unit, .pounds)
        XCTAssertEqual(output.item, "Alaskan salmon")

        output = IngredientParser.shared.parse(string: "0.123 ounces chocolate chips")
        XCTAssertEqual(output.quantity, .float(0.123))
        XCTAssertEqual(output.unit, .ounces)
        XCTAssertEqual(output.item, "chocolate chips")
    }

    func testGroceryFractionQuantity() throws {
        var output: Ingredient

        output = IngredientParser.shared.parse(string: "1/2 lb chicken breast")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(1, 2)))
        XCTAssertEqual(output.unit, .pounds)
        XCTAssertEqual(output.item, "chicken breast")

        output = IngredientParser.shared.parse(string: "1 3/4 cups flour")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(7, 4)))
        XCTAssertEqual(output.unit, .cups)
        XCTAssertEqual(output.item, "flour")

        output = IngredientParser.shared.parse(string: "10 5/8 tsp cinnamon")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(85, 8)))
        XCTAssertEqual(output.unit, .teaspoons)
        XCTAssertEqual(output.item, "cinnamon")
    }

    func testGroceryUnicodeFractionQuantity() throws {
        var output: Ingredient

        output = IngredientParser.shared.parse(string: "⅔ onion")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(2, 3)))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "onion")

        output = IngredientParser.shared.parse(string: "1¼ cups whole   milk")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(5, 4)))
        XCTAssertEqual(output.unit, .cups)
        XCTAssertEqual(output.item, "whole milk")


        output = IngredientParser.shared.parse(string: "3 ⅞ beef rips")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(31, 8)))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "beef rips")
    }
}
