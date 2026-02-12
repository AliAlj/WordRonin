//WordGameLogic.swift
import Foundation

struct WordGameLogic {
    
    static let startWords: [String] = ["ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET", "APRICOT"]
    
    static func pointsForWord(length: Int) -> Int {
        let perLetter = 50
        let base = perLetter * length
        let bonus: Int
        switch length {
        case 0...3: bonus = 0
        case 4: bonus = 50
        case 5: bonus = 150
        default: bonus = 300
        }
        return base + bonus
    }

    static func generatePossibleWords(from letters: [Character], minLength: Int) -> Set<String> {
        let pool = letters.map { String($0).uppercased() }
        var counts: [String: Int] = [:]
        for l in pool { counts[l, default: 0] += 1 }

        func canForm(_ word: String) -> Bool {
            var c = counts
            for ch in word {
                let key = String(ch).uppercased()
                guard let left = c[key], left > 0 else { return false }
                c[key] = left - 1
            }
            return true
        }

        return Set(
            dictionary
                .map { $0.uppercased() }
                .filter { $0.count >= minLength && canForm($0) }
        )
    }

    private static let dictionary: Set<String> = [
        "ORANGE", "ANGER","ARGON","ORGAN","GROAN","RANGE",
        "RANG","RAGE","OGRE","ERGO","AERO","AEON","GORE","GEAR","GONE","EARN","NEAR",
        "ORE","ROE","OAR","AGO","NAG","NOR","EON","EGO","RAN","RAG","AGE","EAR","ERA","ARE","ONE",
        "PLANET", "PLANE","PANEL","PETAL","PLATE","LEAPT","PALET","PENAL", "PLANT", "LEANT",
        "PLEA","PEAL","PALE","LEAP","PELT","LENT","LATE","LEAN","NEAT","TAPE","PATE","PEAT", "TEAL",
        "PAN","PEN","NET","TEN","ANT","TAN","NAP","PAL","LAT","LET","ALE","LEA","APE","EAT","TEA","ATE","TAP","PAT","PET",
        "STREAM","MASTER","TAMERS","SMEAR","STARE","TEARS","RATES","TAMES","TEAMS","SMART",
        "SAME","SEAM","TEAM","MATE","MEAT","TAME","EAST","SEAT","RATE","STAR","EARS","TEAR",
        "ARM","RAM","TAR","RAT","ART","MET","SET","SEA","EAT","ATE","TEA",
        "CAMERA","CREAM","ACRE","CARE","RACE","MARE","AREA","ARC","CAR","ARM","RAM","ERA","ARE","ACE",
        "POCKET","POKE","POET","COKE","TOKE","POCK","TOCK","PECK","COPE","COTE","PET","POT","TOP","COP","TOE","ECO",
        "APRICOT","TOPIC","PATIO","OPTIC","CAPRI","PAIR","TRAP","PORT","PART","TARP","RIP","TIP","PIT","ART","RAT","TAR","TAP","PAT","COP","CAP","CAR","ARC","RAP","PAR","PRO"
    ]
}
