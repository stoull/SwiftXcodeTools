#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

// 写入csv文件
let data = [["Name", "Age", "City"],
            ["Alice", "25", "New York"],
            ["Bob", "30", "Los Angeles"],
            ["Charlie", "22", "Chicago"]]

let csvString = data.map { $0.joined(separator: ",") }.joined(separator: "\n")

do {
    try csvString.write(toFile: "output.csv", atomically: true, encoding: .utf8)
    print("CSV file created successfully.")
} catch {
    print("Error writing CSV file: \(error)")
}



// 读取csv文件
do {
    let csvPath = "output.csv"
    let csvString = try String(contentsOfFile: csvPath, encoding: .utf8)
    
    // Split the CSV string by newline characters to get rows
    let rows = csvString.components(separatedBy: "\n")
    
    // Initialize an empty array to store the parsed data
    var data: [[String]] = []
    
    // Iterate over rows and split each row by commas to get columns
    for row in rows {
        let columns = row.components(separatedBy: ",")
        data.append(columns)
    }
    
    // Print the parsed data
    for row in data {
        print(row)
    }
} catch {
    print("Error reading CSV file: \(error)")
}
