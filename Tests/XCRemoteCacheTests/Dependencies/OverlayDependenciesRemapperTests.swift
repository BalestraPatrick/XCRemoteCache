// Copyright (c) 2021 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

@testable import XCRemoteCache
import XCTest

class OverlayDependenciesRemapperTests: XCTestCase {
    private let overlayReader = OverlayReaderFake(
        mappings: [.init(virtual: "/file.h", local: "/Intermediate/Some/file.h")]
    )

    func testMappingFromLocalToGeneric() throws {
        let remapper = OverlayDependenciesRemapper(overlayReader: overlayReader)

        let dependencies = try remapper.replace(localPaths: ["/Intermediate/Some/file.h"])
        XCTAssertEqual(dependencies, ["/file.h"])
    }

    func testMappingFromGenericToLocal() throws {
        let remapper = OverlayDependenciesRemapper(overlayReader: overlayReader)


        let dependencies = try remapper.replace(genericPaths: ["/file.h"])
        XCTAssertEqual(dependencies, ["/Intermediate/Some/file.h"])
    }

    func testGenericDependenciesAreNotMerged() throws {
        let remapper = OverlayDependenciesRemapper(overlayReader: overlayReader)


        let dependencies = try remapper.replace(localPaths: ["/Intermediate/Some/file.h", "/file.h"])
        XCTAssertEqual(dependencies, ["/file.h", "/file.h"])
    }

    func testLocalDependenciesAreNotMerged() throws {
        let remapper = OverlayDependenciesRemapper(overlayReader: overlayReader)


        let dependencies = try remapper.replace(genericPaths: ["/Intermediate/Some/file.h", "/file.h"])
        XCTAssertEqual(dependencies, ["/Intermediate/Some/file.h", "/Intermediate/Some/file.h"])
    }

    func testMappingsAreReadOnce() throws {
        let remapper = OverlayDependenciesRemapper(overlayReader: overlayReader)

        let firstDependencies = try remapper.replace(localPaths: ["/Intermediate/Some/file.h"])
        // Update mappings in-fly to verify the previous value is cached in a remapper
        overlayReader.mappings = []
        let secondDependencies = try remapper.replace(localPaths: ["/Intermediate/Some/file.h"])

        XCTAssertEqual(firstDependencies, ["/file.h"])
        XCTAssertEqual(secondDependencies, ["/file.h"])
    }
}
