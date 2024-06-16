#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

// WHAT
// 1. Find Missing keys in other Localisation files
// 2. Find potentially untranslated keys
// 3. Find Duplicate keys
// 4. Find Unused keys and generate script to delete them all at once

// 需要打印或在工程中显示的异常类型
let printResults: Set<CheckResultType> = [.unused]

// 需要输出的异常翻译类型
let saveResults: Set<CheckResultType> = [.unused]

// MARK: Start Of Configurable Section

/*
 You can enable or disable the script whenever you want
 */
let enabled = true

/*
 Put your path here, example ->  Resources/Localizations/Languages
 */
let relativeLocalizableFolders = "/LocalDebug/基类"

/*
 This is the path of your source folder which will be used in searching
 for the localization keys you actually use in your project
 */
let relativeSourceFolder = "/LocalDebug"

// GTLLString\(@\"([\w\.\(\)\{\}:（），/“”><：《》_。？\?%\*-\+,~ ， -]+)\"\)
// @\"([\w\.\(\)\{\}:（），/“”><：《》_。？\?%\*-\+,~ ， -]+)\"
/*
 Those are the regex patterns to recognize localizations.
 */
let patterns = [
    "\\(@\"(.*)\"\\)",
        "GTLLString\\(@\"([\\w\\.\\\\)\\(:（），/“”><：《》_。？\\?%\\*,~ -]+)\"", // GTLLString() 方法
//    "GTLLString\\(@\"(.*)\"",
    "NSLocalized(Format)?String\\(\\s*@?\"([\\w\\.]+)\"", // Swift and Objc Native
    "Localizations\\.((?:[A-Z]{1}[a-z]*[A-z]*)*(?:\\.[A-Z]{1}[a-z]*[A-z]*)*)", // Laurine Calls
    "L10n.tr\\(key: \"(\\w+)\"", // SwiftGen generation
    "ypLocalized\\(\"(.*)\"\\)",
    "\"(.*)\".localized" // "key".localized pattern
]

/*
 Those are the keys you don't want to be recognized as "unused"
 For instance, Keys that you concatenate will not be detected by the parsing
 so you want to add them here in order not to create false positives :)
 */
let ignoredFromUnusedKeys: [String] = []
/* example
let ignoredFromUnusedKeys = [
    "NotificationNoOne",
    "NotificationCommentPhoto",
    "NotificationCommentHisPhoto",
    "NotificationCommentHerPhoto"
]
*/

let masterLanguage = "zh-Hans"

/*
 Sanitizing files will remove comments, empty lines and order your keys alphabetically.
 */
let sanitizeFiles = false

/*
 Determines if there are multiple localizations or not.
 */
let singleLanguage = false

/*
 Determines if we should show errors if there's a key within the app
 that does not appear in master translations.
*/
let checkForUntranslated = true

// MARK: End Of Configurable Section
// MARK: -




if enabled == false {
    print("Localization check cancelled")
    
    exit(000)
}

// Detect list of supported languages automatically
func listSupportedLanguages() -> [String] {
    var sl: [String] = []
    let path = FileManager.default.currentDirectoryPath + relativeLocalizableFolders
    if !FileManager.default.fileExists(atPath: path) {
        print("Invalid configuration: \(path) does not exist.")
        exit(1)
    }
    let enumerator = FileManager.default.enumerator(atPath: path)
    let extensionName = "lproj"
    print("Found these languages:")
    while let element = enumerator?.nextObject() as? String {
        if element.hasSuffix(extensionName) {
            print(element)
            let name = element.replacingOccurrences(of: ".\(extensionName)", with: "")
            sl.append(name)
        }
    }
    return sl
}

let supportedLanguages = listSupportedLanguages()
var ignoredFromSameTranslation: [String: [String]] = [:]
let path = FileManager.default.currentDirectoryPath + relativeLocalizableFolders
var numberOfWarnings = 0
var numberOfErrors = 0

struct LocalizationFiles {
    var name = ""
    var keyValue: [String: String] = [:]
    var linesNumbers: [String: Int] = [:]

    init(name: String) {
        self.name = name
        process()
    }
    
    var duplicatedKeyValues: [String: String] = [:]
    

    mutating func process() {
        if sanitizeFiles {
            removeCommentsFromFile()
            removeEmptyLinesFromFile()
            sortLinesAlphabetically()
        }
        let location = singleLanguage ? "\(path)/Localizable.strings" : "\(path)/\(name).lproj/Localizable.strings"
        guard let string = try? String(contentsOfFile: location, encoding: .utf8) else {
            return
        }

        let lines = string.components(separatedBy: .newlines)
        keyValue = [:]

        let pattern = "\"(.*)\" = \"(.+)\";"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        var ignoredTranslation: [String] = []

        for (lineNumber, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: (line as NSString).length)

            // Ignored pattern
            let ignoredPattern = "\"(.*)\" = \"(.+)\"; *\\/\\/ *ignore-same-translation-warning"
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
                    let str = "\(path)/\(name).lproj"
                        + "/Localizable.strings:\(linesNumbers[key]!): "
                        + "error: [Duplication] \"\(key)\" "
                        + "is duplicated in \(name.uppercased()) file"
                    print(str)
                    numberOfErrors += 1
                    duplicatedKeyValues[key] = value
                } else {
                    keyValue[key] = value
                    linesNumbers[key] = lineNumber + 1
                }
            }
        }
        print(ignoredFromSameTranslation)
        ignoredFromSameTranslation[name] = ignoredTranslation
    }

    func rebuildFileString(from lines: [String]) -> String {
        return lines.reduce("") { (r: String, s: String) -> String in
            (r == "") ? (r + s) : (r + "\n" + s)
        }
    }

    func removeEmptyLinesFromFile() {
        let location = "\(path)/\(name).lproj/Localizable.strings"
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            var lines = string.components(separatedBy: .newlines)
            lines = lines.filter { $0.trimmingCharacters(in: .whitespaces) != "" }
            let s = rebuildFileString(from: lines)
            try? s.write(toFile: location, atomically: false, encoding: .utf8)
        }
    }

    func removeCommentsFromFile() {
        let location = "\(path)/\(name).lproj/Localizable.strings"
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            var lines = string.components(separatedBy: .newlines)
            lines = lines.filter { !$0.hasPrefix("//") }
            let s = rebuildFileString(from: lines)
            try? s.write(toFile: location, atomically: false, encoding: .utf8)
        }
    }

    func sortLinesAlphabetically() {
        let location = "\(path)/\(name).lproj/Localizable.strings"
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

// MARK: - Load Localisation Files in memory

let masterLocalizationFile = LocalizationFiles(name: masterLanguage)
let localizationFiles = supportedLanguages
    .filter { $0 != masterLanguage }
    .map { LocalizationFiles(name: $0) }

// MARK: - Detect Unused Keys

let sourcesPath = FileManager.default.currentDirectoryPath + relativeSourceFolder
let fileManager = FileManager.default
let enumerator = fileManager.enumerator(atPath: sourcesPath)
var localizedStrings: [String] = []
while let swiftFileLocation = enumerator?.nextObject() as? String {
    // checks the extension
    if swiftFileLocation.hasSuffix(".swift") || swiftFileLocation.hasSuffix(".m") || swiftFileLocation.hasSuffix(".mm") {
        let location = "\(sourcesPath)/\(swiftFileLocation)"
        if let string = try? String(contentsOfFile: location, encoding: .utf8) {
            var separateFileStrings: [String] = []
            for p in patterns {
                let regex = try? NSRegularExpression(pattern: p, options: [])
                let range = NSRange(location: 0, length: (string as NSString).length) // Obj c wa
                regex?.enumerateMatches(in: string,
                                        options: [],
                                        range: range,
                                        using: { result, _, _ in
                                            if let r = result {
                                                let value = (string as NSString).substring(with: r.range(at: r.numberOfRanges - 1))
                                                localizedStrings.append(value)
                                                separateFileStrings.append(value)
                                            }
                })
            }
            // 测试匹配用
//            if location == "/Users/hut/Desktop/shineplugin/ios/LocalDebug/GTAppTools/GTUploadManager/GTUploadManager.m" {
//                for iStr in separateFileStrings {
//                    print("GTAppTools/GTUploadManager/GTUploadManager.m文件中匹配到的key: \(iStr)")
//                }
//            }
        }
    }
}

var masterKeys = Set(masterLocalizationFile.keyValue.keys)
let usedKeys = Set(localizedStrings)
let ignored = Set(ignoredFromUnusedKeys)
let unused = masterKeys.subtracting(usedKeys).subtracting(ignored)
let untranslated = usedKeys.subtracting(masterKeys)

// Here generate Xcode regex Find and replace script to remove dead keys all at once!
var replaceCommand = "\"("
var counter = 0
for v in unused {
    var str = "\(path)/\(masterLocalizationFile.name).lproj/Localizable.strings:\(masterLocalizationFile.linesNumbers[v]!): "
    str += "error: [Unused Key] \"\(v)\" is never used"
    print(str)
    numberOfErrors += 1
    if counter != 0 {
        replaceCommand += "|"
    }
    replaceCommand += v
    if counter == unused.count - 1 {
        replaceCommand += ")\" = \".*\";"
    }
    counter += 1
}

print(">>>>>>>>> 移除所有没有用到的翻译正则：")
print(replaceCommand)

// MARK: - Compare each translation file against master (en)

for file in localizationFiles {
    for k in masterLocalizationFile.keyValue.keys {
        if let v = file.keyValue[k] {
            if v == masterLocalizationFile.keyValue[k] {
                if !ignoredFromSameTranslation[file.name]!.contains(k) {
                    let str = "\(path)/\(file.name).lproj/Localizable.strings"
                        + ":\(file.linesNumbers[k]!): "
                        + "warning: [Potentially Untranslated] \"\(k)\""
                        + "in \(file.name.uppercased()) file doesn't seem to be localized"
                    print(str)
                    numberOfWarnings += 1
                }
            }
        } else {
            var str = "\(path)/\(file.name).lproj/Localizable.strings:\(masterLocalizationFile.linesNumbers[k]!): "
            str += "error: [Missing] \"\(k)\" missing from \(file.name.uppercased()) file"
            print(str)
            numberOfErrors += 1
        }
    }

    let redundantKeys = file.keyValue.keys.filter { !masterLocalizationFile.keyValue.keys.contains($0) }

    for k in redundantKeys {
        let str = "\(path)/\(file.name).lproj/Localizable.strings:\(file.linesNumbers[k]!): "
            + "error: [Redundant key] \"\(k)\" redundant in \(file.name.uppercased()) file"

        print(str)
    }
}

if checkForUntranslated {
    for key in untranslated {
        var str = "\(path)/\(masterLocalizationFile.name).lproj/Localizable.strings:1: "
        str += "error: [Missing Translation] \(key) is not translated"

        print(str)
        numberOfErrors += 1
    }
}

print("Number of warnings : \(numberOfWarnings)")
print("Number of errors : \(numberOfErrors)")

// MARK: - 写入文件部分
let checkResultFolder = "0CheckResult"

// MARK: - 翻译结果类型
// 结果类型
enum CheckResultType {
    case unused
    case missing
    case redundant
    case untranslated
    case duplication

    var filePath: String {
        switch self {
        case .unused:
            return checkResultFolder + "/unused.strings"
        case .missing:
            return checkResultFolder + "/missing.strings"
        case .redundant:
            return checkResultFolder + "/redundant.strings"
        case .untranslated:
            return checkResultFolder + "/untranslated.strings"
        case .duplication:
            return checkResultFolder + "/duplication.strings"
        }
    }
    
    var des: String {
        switch self {
        case .unused:
            return "======这里记录的是在工程里没有引用的翻译=====\n"
        case .missing:
            return "======这里记录的是在工程里有引用，但在主文件中没有找到的翻译=====\n"
        case .redundant:
            return "======这里记录的是有多次引用的翻译=====\n"
        case .untranslated:
            return "======但在主文件中有翻译，但在其它语言中没有的翻译=====\n"
        case .duplication:
            return "======但在主文件中有翻译，并且有重复key=====\n"
        }
    }
}

func cleanResultFolder() {
    do {
        if FileManager.default.fileExists(atPath: checkResultFolder) {
            do {
                try fileManager.removeItem(atPath: checkResultFolder)
                print("结果目录清空成功")
            } catch {
                print("结果目录清空失败: \(error)")
            }
        }
        
        try FileManager.default.createDirectory(atPath: checkResultFolder, withIntermediateDirectories: true)
        for type in saveResults {
            FileManager.default.createFile(atPath: type.filePath, contents: type.des.data(using: .utf8)!)
        }
    } catch {
        print("结果目录清空失败: \(checkResultFolder) error: \(error)")
    }
}

// 将没有翻译的key写入文件
func wirteArrayToFile(_ sArray: Set<String>, type: CheckResultType) {
    let fileURL = URL(fileURLWithPath: type.filePath)
    do {
        let aStr = sArray.joined(separator: "\n")
        try aStr.write(to: fileURL, atomically: true, encoding: .utf8)
    } catch {
        print("Error writing to file: \(error)")
    }
}

// 清空结果目录
cleanResultFolder()

// en
let enLocalizationFile = LocalizationFiles(name: "en")

// 写入文件
saveResults.forEach { type in
    var resultStrs: Set<String> = []
    switch type {
    case .unused:
        resultStrs = unused
        
        var resultString = ""
        
        var zhStrs: [String] = []
        var enStrs: [String] = []
        for v in unused {
            let cn = "\"\(v)\" = \"\(masterLocalizationFile.keyValue[v] ?? "")\"";
            let en = "\"\(v)\" = \"\(enLocalizationFile.keyValue[v] ?? "")\"";
            
            zhStrs.append(cn)
            enStrs.append(en)
        }
        
        let zhString = zhStrs.joined(separator: "\n")
        resultString = zhString + "\n\n\n\n\n ======= 以下是英文未用到的 ======= \n\n\n\n"
        let enString = enStrs.joined(separator: "\n")
        resultString = resultString + enString
        
        try? resultString.write(toFile: CheckResultType.unused.filePath, atomically: true, encoding: .utf8)
    case .missing:
        resultStrs = unused
    case .redundant:
        resultStrs = unused
    case .untranslated:
        resultStrs = unused
    case .duplication:
        ()
//        resultStrs = masterLocalizationFile.duplicatedKeyValues
    }
//    wirteArrayToFile(unused, type: .unused)
}

if numberOfErrors > 0 {
    exit(1)
}
