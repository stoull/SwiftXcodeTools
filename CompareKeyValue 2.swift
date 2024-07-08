#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

let sourcesPath1 = FileManager.default.currentDirectoryPath + "/0CheckResult_full/整理过(剔除没有引用的翻译)后_cn.strings"
let sourcesPath2 = FileManager.default.currentDirectoryPath + "/0CheckResult/整理过(剔除没有引用的翻译)后_cn.strings"

let file1 = LocalizationFiles(filePath: sourcesPath1)
let file2 = LocalizationFiles(filePath: sourcesPath2)

let fullKeys = Set(file1.keyValue.keys)
let accurateKeys = Set(file2.keyValue.keys)

let dKeys = fullKeys.subtracting(accurateKeys)
let dKeyValues = accurateKeys.subtracting(fullKeys)

let resultMsg = "// 大范围匹配到的总条数：\(fullKeys.count) 精确匹配到的总条数：\(accurateKeys.count)\n// 精确没有匹配到的条数: \(dKeys.count) 大范围没有匹配到的条数: \(dKeyValues.count)"
print(resultMsg)

var diffKeyValues: [String: String] = [:]
for v in dKeys {
//    print("\(v)")
    diffKeyValues[v] = file1.keyValue[v]
}

var diffKeyValues2: [String: String] = [:]
for v in dKeyValues {
//    print("\(v)")
    diffKeyValues2[v] = file2.keyValue[v]
}

var diffStrings: [String] = [resultMsg]
for (key,value) in diffKeyValues {
    let str = "\"\(key)\" = \"\(value)\";";
    diffStrings.append(str)
}

var diffStrings2: [String] = [resultMsg]
for (key,value) in diffKeyValues2 {
    let str = "\"\(key)\" = \"\(value)\";";
    diffStrings2.append(str)
}

let diffString = diffStrings.joined(separator: "\n")
let writeFilePath = FileManager.default.currentDirectoryPath + "/CompareKey精确没有匹配到的.strings"
try? diffString.write(toFile: writeFilePath, atomically: true, encoding: .utf8)

let diffString2 = diffStrings2.joined(separator: "\n")
let writeFilePath2 = FileManager.default.currentDirectoryPath + "/CompareKey大范围没有匹配到的.strings"
try? diffString2.write(toFile: writeFilePath2, atomically: true, encoding: .utf8)

let sanitizeFiles = false
struct LocalizationFiles {
    var filePath = ""
    var keyValue: [String: String] = [:]
    var linesNumbers: [String: Int] = [:]

    init(filePath: String) {
        self.filePath = filePath
        process()
    }
    
    var duplicatedKeyValues: [String: String] = [:]
    

    mutating func process() {
        if sanitizeFiles {
            removeCommentsFromFile()
            removeEmptyLinesFromFile()
            sortLinesAlphabetically()
        }
        let location = filePath
        guard let string = try? String(contentsOfFile: location, encoding: .utf8) else {
            return
        }

        let lines = string.components(separatedBy: .newlines)
        keyValue = [:]

        let pattern = "\"(.*)\" ?= ?\"(.+)\";"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        var ignoredTranslation: [String] = []

        for (lineNumber, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: (line as NSString).length)

            // Ignored pattern
            let ignoredPattern = "\"(.*)\" ?= ?\"(.+)\"; *\\/\\/ *ignore-same-translation-warning"
            let ignoredRegex = try? NSRegularExpression(pattern: ignoredPattern, options: [])
            if let ignoredMatch = ignoredRegex?.firstMatch(in: line,
                                                           options: [],
                                                           range: range) {
                let key = (line as NSString).substring(with: ignoredMatch.range(at: 1))
                ignoredTranslation.append(key)
            }

            if let firstMatch = regex?.firstMatch(in: line, options: [], range: range) {
                let key = (line as NSString).substring(with: firstMatch.range(at: 1))
                let value = (line as NSString).substring(with: firstMatch.range(at: 2))

                if keyValue[key] != nil {
//                    numberOfErrors += 1
                    duplicatedKeyValues[key] = value
                } else {
                    keyValue[key] = value
                    linesNumbers[key] = lineNumber + 1
                }
            }
        }
    }

    func rebuildFileString(from lines: [String]) -> String {
        return lines.reduce("") { (r: String, s: String) -> String in
            (r == "") ? (r + s) : (r + "\n" + s)
        }
    }

    func removeEmptyLinesFromFile() {
        let location = filePath
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            var lines = string.components(separatedBy: .newlines)
            lines = lines.filter { $0.trimmingCharacters(in: .whitespaces) != "" }
            let s = rebuildFileString(from: lines)
            try? s.write(toFile: location, atomically: false, encoding: .utf8)
        }
    }

    func removeCommentsFromFile() {
        let location = filePath
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            var lines = string.components(separatedBy: .newlines)
            lines = lines.filter { !$0.hasPrefix("//") }
            let s = rebuildFileString(from: lines)
            try? s.write(toFile: location, atomically: false, encoding: .utf8)
        }
    }

    func sortLinesAlphabetically() {
        let location = filePath
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            let lines = string.components(separatedBy: .newlines)

            var s = ""
            for (i, l) in sortAlphabetically(lines).enumerated() {
                s += l
                if i != lines.count - 1 {
                    s += "\n"
                }
            }
            try? s.write(toFile: location, atomically: false, encoding: .utf8)
        }
    }

    func removeEmptyLinesFromLines(_ lines: [String]) -> [String] {
        return lines.filter { $0.trimmingCharacters(in: .whitespaces) != "" }
    }

    func sortAlphabetically(_ lines: [String]) -> [String] {
        return lines.sorted()
    }
}
