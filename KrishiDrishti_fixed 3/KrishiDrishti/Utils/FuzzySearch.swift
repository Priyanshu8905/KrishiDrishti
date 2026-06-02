// Utils/FuzzySearch.swift
// KrishiDrishti — Fuzzy string search utility

import Foundation

struct FuzzySearch {

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var curr = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            curr[0] = i
            for j in 1...b.count {
                curr[j] = a[i-1] == b[j-1] ? prev[j-1] : min(prev[j-1]+1, curr[j-1]+1, prev[j]+1)
            }
            prev = curr
        }
        return curr[b.count]
    }

    static func score(query: String, candidate: String) -> Double {
        let lq = query.lowercased(), lc = candidate.lowercased()
        if lq == lc { return 1.0 }
        let dist  = Double(levenshtein(lq, lc))
        let maxL  = Double(max(lq.count, lc.count))
        var score = max(0, 1 - dist / maxL)
        if lc.hasPrefix(lq)   { score = min(1.0, score + 0.2) }
        if lc.contains(lq)    { score = min(1.0, score + 0.1) }
        return score
    }
}
