//
//  String+extensions.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//


extension String {
    public func toSnakeCase(splitCharacter: Character = "_") -> String {
        guard !self.isEmpty else { return self }
        
        var result = ""
        
        for (index, char) in self.enumerated() {
            if char.isUppercase && index > 0 {
                result.append(splitCharacter)
            }
            result += char.lowercased()
        }
        return result
    }
}
