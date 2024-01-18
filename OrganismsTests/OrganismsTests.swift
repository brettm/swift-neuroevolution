//
//  OrganismsTests.swift
//  OrganismsTests
//
//  Created by Brett Meader on 16/01/2024.
//

import XCTest

@testable import Organisms

final class OrganismsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testModel() throws {
        let model = OrganismModel()
//        let pred = model.predict(targetDirection: (-0.7278094289640089, -0.6857794361972976))
        let pred = model.predict(targetDirection: (-0.7278, -0.68577))
        print(pred)
    }

}
