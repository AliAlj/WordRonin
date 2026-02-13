// WordGameLogic.swift
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

        // ORANGE
        "ORANGE",
        "ANGER","ARGON","GROAN","ORGAN","RANGE",
        "EARN","GEAR","GONE","GORE","NEAR","OGRE","ERGO","RAGE","RANG","ROAN",
        "AGE","AGO","ARE","EAR","ERA","EGO","EON","NAG","NOR","OAR","ONE","ORE","RAG","RAN","ROE",

        // PLANET
        "PLANET",
        "LEANT","LEAPT","LENT","PANEL","PATE","PENAL","PETAL","PLANE","PLANT","PLATE","PLEAT","PLAT",
        "LEAN","LANE","LATE","LEAP","NEAT","PANE","PANT","PALE","PEAL","PEAT","PELT","PLAN","PLEA","TALE","TAPE","TEAL",
        "ALE","APE","ANT","ATE","EAT","LAP","LAT","LEA","LET","NAP","NET","PAL","PAN","PAT","PEA","PEN","PET","TAN","TAP","TEA","TEN",

        // STREAM
        "STREAM","MASTER","TAMERS","MATERS",
        "SMART","SMEAR","STARE","STEAM","TEARS","RATES","TAMES","TEAMS","MARES","MATER","ASTER",
        "EAST","EARS","EATS","ERAS","MARE","MARS","MEAT","MATE","METS","RATE","REST","SEAM","SEAR","SEAT","SAME","SATE","STAR","STEM","TAME","TARE","TEAM","TEAR","TEAS","ARMS",
        "ARM","ART","ARE","EAR","ERA","EAT","ATE","TEA","MAR","RAM","RAT","TAR","MET","SET","SEA","SAT",

        // CAMERA
        "CAMERA",
        "CREAM","MACER",
        "ACRE","AREA","CARE","RACE","REAM","CAME","MACE","ACME","MARE","CRAM","ACER",
        "ACE","ARC","ARE","ARM","CAM","CAR","EAR","ERA","MAC","MAR","RAM",

        // POCKET
        "POCKET",
        "PECK","COPE","COKE","POET","POKE","TOCK","TOKE","TOPE","KETO","POCK",
        "COP","COT","ECO","OPT","PET","POT","TOE","TOP",

        // APRICOT
        "APRICOT",
        "TROPIC","CAPTOR","ACTOR",
        "TOPIC","OPTIC","PATIO","RATIO","CAPRI",
        "COAT","TACO","ORCA","CROP","TRIO","PAIR","PART","PORT","TARP","TRAP","PACT","CART","PITA","RIOT",
        "AIR","ARC","ART","CAP","CAR","COP","COT","OAR","OAT","PAR","PAT","PIT","POT","PRO","RAP","RAT","RIP","ROT","TAR","TAP","TIP","TOP"
    ]
}
