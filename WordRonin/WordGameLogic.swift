// WordGameLogic.swift
import Foundation

struct WordGameLogic {

    // MARK: - Word Sets
    // Each entry is a root word. Sub-words are stored in the dictionary below.
    static let startWords: [String] = [
        "ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET", "APRICOT",
        "CASTLE", "DANCER", "FLOWER", "GARDEN", "HUNTER", "MARKET",
        "NATURE", "OYSTER", "PIRATE", "ROCKET", "FOREST", "BANTER", "CARPET"
    ]

    // MARK: - Scoring
    static func pointsForWord(length: Int) -> Int {
        let perLetter = 50
        let base = perLetter * length
        let bonus: Int
        switch length {
        case 0...3: bonus = 0
        case 4:     bonus = 50
        case 5:     bonus = 150
        default:    bonus = 300
        }
        return base + bonus
    }

    // MARK: - Word Generation
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

    // MARK: - Dictionary
    // Comprehensive word list covering all startWords above.
    // Sorted by root word for easy maintenance.
    private static let dictionary: Set<String> = [

        // ── ORANGE ───────────────────────────────────────────────────────────
        "ORANGE",
        "ANGER","ARGON","GROAN","ORGAN","RANGE",
        "EARN","GEAR","GONE","GORE","NEAR","OGRE","ERGO","RAGE","RANG","ROAN",
        "AGE","AGO","ARE","EAR","ERA","EGO","EON","NAG","NOR","OAR","ONE","ORE","RAG","RAN","ROE",

        // ── PLANET ───────────────────────────────────────────────────────────
        "PLANET",
        "LEANT","PANEL","PATE","PENAL","PETAL","PLANE","PLANT","PLATE","PLEAT","PLAT",
        "LEAN","LANE","LATE","LEAP","NEAT","PANE","PANT","PALE","PEAL","PEAT","PELT","PLAN","PLEA","TALE","TAPE","TEAL",
        "ALE","APE","ANT","ATE","EAT","LAP","LAT","LEA","LET","NAP","NET","PAL","PAN","PAT","PEA","PEN","PET","TAN","TAP","TEA","TEN",

        // ── STREAM ───────────────────────────────────────────────────────────
        "STREAM","MASTER","TAMERS","MATERS",
        "SMART","SMEAR","STARE","STEAM","TEARS","RATES","TAMES","TEAMS","MARES","MATER","ASTER","TRAMS","MATES",
        "EAST","EARS","EATS","ERAS","MARE","MARS","MEAT","MATE","RATE","REST","SEAM","SEAR","SEAT","SAME","SATE","STAR","STEM","TAME","TARE","TEAM","TEAR","TEAS","ARMS","TRAM","MAST","MART","REAM",
        "ARM","ART","ARE","EAR","ERA","EAT","ATE","TEA","MAR","RAM","RAT","TAR","MET","SET","SEA","SAT","TAM",

        // ── CAMERA ───────────────────────────────────────────────────────────
        "CAMERA",
        "CREAM","MACER","ARECA",
        "ACRE","AREA","CARE","RACE","REAM","CAME","MACE","ACME","MARE","CRAM","ACER",
        "ACE","ARC","ARE","ARM","CAM","CAR","EAR","ERA","MAC","MAR","RAM",

        // ── POCKET ───────────────────────────────────────────────────────────
        "POCKET",
        "PECK","COPE","COKE","POET","POKE","TOCK","TOKE","TOPE","KETO","POCK",
        "COP","COT","ECO","OPT","PET","POT","TOE","TOP",

        // ── APRICOT ──────────────────────────────────────────────────────────
        "APRICOT",
        "TROPIC","CAPTOR","ACTOR",
        "TOPIC","OPTIC","PATIO","RATIO",
        "COAT","TACO","ORCA","CROP","TRIO","PAIR","PART","PORT","TARP","TRAP","PACT","CART","PITA","RIOT","ATOP",
        "AIR","ARC","ART","CAP","CAR","COP","COT","OAR","OAT","PAR","PAT","PIT","POT","PRO","RAP","RAT","RIP","ROT","TAR","TAP","TIP","TOP","OCA",

        // ── CASTLE ───────────────────────────────────────────────────────────
        "CASTLE","CLEATS",
        "CASTE","CLEAT","ECLAT","LACES","SCALE","SLATE","STALE","TALES","LEAST","STEAL","TACES",
        "CASE","CAST","CATS","LACE","LAST","LATE","LEST","SALT","SALE","SEAL","SEAT","SECT","SCAT","TACE","TALE","TALC","TEAL",
        "ACE","ATE","CAT","EAT","LAT","LET","SAC","SAT","SEA","SET","TEA",

        // ── DANCER ───────────────────────────────────────────────────────────
        "DANCER","CRANED",
        "ACNED","CANED","CRANE","DANCE","NACRE",
        "CARD","CARE","DARE","DEAR","DEAN","EARN","NARC","RACE","RAND","READ","REND","CANE","ACNE","ARCED",
        "ACE","AND","ANE","ARC","CAN","CAR","DAN","DEN","END","ERA","EAR","RAN","RED","CAD","RAD",

        // ── FLOWER ───────────────────────────────────────────────────────────
        "FLOWER","FOWLER",
        "FLOE","FLEW","FORE","FOWL","LORE","LOWE","ORLE","ROLE","WORE","WOLF",
        "ELF","FOR","FOE","LOW","OWE","OWL","ROE","ROW","WOE",

        // ── GARDEN ───────────────────────────────────────────────────────────
        "GARDEN","RANGED","GANDER","DANGER",
        "ANGER","RANGE","GRAND",
        "AGED","DARE","DEAN","DRAG","EARN","GEAR","GRAD","GRAN","NARD","RAND","RANG","READ","REND",
        "AGE","AND","ARE","DAN","DEN","EAR","END","ERA","GAD","NAG","RAG","RAN","RED",

        // ── HUNTER ───────────────────────────────────────────────────────────
        "HUNTER",
        "RUNE","HUNT","HURT","RUNT","TUNE","TURN","TERN","RENT","HERN",
        "HEN","HER","HUE","NUT","RUE","RUN","RUT","TEN","THE","TUN","URN","NET","NTH",

        // ── MARKET ───────────────────────────────────────────────────────────
        "MARKET",
        "MAKER","TAKER","MATER",
        "RAKE","MARE","MARK","MART","MEAT","MAKE","MATE","RATE","REAM","TAKE","TAME","TEAM","TERM","TREK",
        "ARE","ARM","ATE","EAR","EAT","ERA","MAR","MAT","MET","RAM","RAT","TAM","TAR","TEA",

        // ── NATURE ───────────────────────────────────────────────────────────
        "NATURE",
        "URATE","UREA","ANTRE",
        "ANTE","AUNT","EARN","NEAR","RANT","RATE","RUNE","RUNT","TARE","TARN","TEAR","TUNE","TURN","TERN","TUNA",
        "ANT","ARE","ATE","EAR","EAT","ERA","NUT","RAN","RAT","RUE","RUN","RUT","TAR","TAU","TEA","TEN","TUN","URN","NET",

        // ── OYSTER ───────────────────────────────────────────────────────────
        "OYSTER","STOREY","TOYERS",
        "STORY","STORE","TORES","TYRES","RESTY","TYERS",
        "ROTE","ROSY","SORT","SORE","TORE","TORY","TOEY","TOYS","TYES","YORE",
        "ORE","ORT","ROE","ROT","RYE","SET","SOT","SOY","STY","TOE","TOY","TYE","YES","YET",

        // ── PIRATE ───────────────────────────────────────────────────────────
        "PIRATE","PARTIE","TRAIPE",
        "IRATE","TAPIR","ATRIP","TAPER","TRIPE",
        "PAIR","PARE","PART","PATE","PIER","PITA","RAPT","RATE","REAP","RIPE","TAPE","TARE","TEAR","TIER","TIRE","TRAP","TRIP",
        "AIR","APE","APT","ARE","ART","ATE","EAR","EAT","ERA","PAR","PAT","PEA","PIE","PIT","RAP","RAT","RIP","TAP","TAR","TEA","TIP",

        // ── ROCKET ───────────────────────────────────────────────────────────
        "ROCKET",
        "TROKE","TOKER","OCKER",
        "COKE","CORE","CORK","ROTE","RECK","ROCK","TOCK","TOKE","TREK","TORE",
        "COT","ECO","ORE","ORT","ROE","ROT","TOE",

        // ── FOREST ───────────────────────────────────────────────────────────
        "FOREST","FORTES","FOSTER","SOFTER",
        "FORES","FORTE","FRETS","FROST","STORE","TORES",
        "FORE","FORT","FROE","FRET","ORES","REST","ROES","ROTE","ROTS","SERF","SORT","SORE","TORE",
        "FOR","FOE","FRO","ORE","ORT","ROE","ROT","SET","SOT","TOE",

        // ── BANTER ───────────────────────────────────────────────────────────
        "BANTER",
        "ANTRE","BRANT",
        "ANTE","BARE","BARN","BATE","BEAN","BEAR","BEAT","BRAN","BRAT","EARN","RANT","RATE","TARE","TEAR","TERN","RENT",
        "ANE","ANT","ATE","BAN","BAR","BAT","BET","EAR","EAT","ERA","NAB","NET","RAN","RAT","TAB","TAN","TAR","TEA","TEN",

        // ── CARPET ───────────────────────────────────────────────────────────
        "CARPET","CARET",
        "CAPER","CRAPE","TAPER","TRACE","REACT","CARTE","CRATE",
        "ACRE","APER","CARE","CARP","CART","PACE","PARE","PART","PATE","RACE","RAPT","RATE","REAP","TACE","TAPE","TARE",
        "ACE","APE","APT","ARC","ARE","ART","ATE","CAP","CAR","CAT","EAR","EAT","ERA","PAR","PAT","PEA","RAP","RAT","TAP","TAR","TEA",
    ]
}
