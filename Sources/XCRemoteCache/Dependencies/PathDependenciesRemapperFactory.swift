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

import Foundation

enum PathDependenciesRemapperFactoryError: Error {
    /// Remapping keys are duplicated and can lead to undetermined results
    case mappingKeyDuplication
}

class PathDependenciesRemapperFactory {
    func build(
        orderKeys: [String],
        envs: [String: String],
        customMappings: [String: String]
    ) throws -> StringDependenciesRemapper {
        let mappingMap = try envs.merging(customMappings) { envValue, outOfBandMapping in
            throw PathDependenciesRemapperFactoryError.mappingKeyDuplication
        }
        let mappingOrderKeys =  orderKeys + customMappings.keys
        let mappings: [StringDependenciesRemapper.Mapping] = mappingOrderKeys.compactMap { key in
            guard let localURL: URL = mappingMap.readEnv(key: key) else {
                debugLog("\(key) ENV to map a dependency is not defined")
                return nil
            }
            infoLog("Found url to remapp: \(localURL). Remapping: \(localURL.standardized.path)")
            return StringDependenciesRemapper.Mapping(generic: "$(\(key))", local: localURL.standardized.path)
        }
        return StringDependenciesRemapper(mappings: mappings)
    }
}
