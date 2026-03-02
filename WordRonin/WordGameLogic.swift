// WordGameLogic.swift
import Foundation

struct WordGameLogic {

    // MARK: - Word Sets
    // Each entry is a root word. Sub-words are stored in the dictionary below.
    static let startWords: [String] = [
        "ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET", "APRICOT",
        "BRIDGE", "CASTLE", "DANCER", "FLOWER", "GARDEN", "HUNTER",
        "JUNGLE", "MARKET", "NATURE", "OYSTER", "PIRATE", "QUARTZ",
        "ROCKET", "SILVER", "TEMPLE", "UNFOLD", "VICTOR", "WINDOW",
        "FOREST", "ANCHOR", "BANTER", "CARPET", "DONKEY"
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
        "AGE","AGO","ARE","EAR","ERA","EGO","EON","NAG","NOR","OAR","ONE","ORE","RAG","RAN","ROE","GAN","GON","NAE",

        // ── PLANET ───────────────────────────────────────────────────────────
        "PLANET",
        "LEANT","PANEL","PATE","PENAL","PETAL","PLANE","PLANT","PLATE","PLEAT","PLAT",
        "LEAN","LANE","LATE","LEAP","NEAT","PANE","PANT","PALE","PEAL","PEAT","PELT","PLAN","PLEA","TALE","TAPE","TEAL","ALPS","YELP",
        "ALE","APE","ANT","ATE","EAT","LAP","LAT","LEA","LET","NAP","NET","PAL","PAN","PAT","PEA","PEN","PET","TAN","TAP","TEA","TEN","ELT","LAE","NAE",

        // ── STREAM ───────────────────────────────────────────────────────────
        "STREAM","MASTER","TAMERS","MATERS",
        "SMART","SMEAR","STARE","STEAM","TEARS","RATES","TAMES","TEAMS","MARES","MATER","ASTER","TRAMS",
        "EAST","EARS","EATS","ERAS","MARE","MARS","MEAT","MATE","RATE","REST","SEAM","SEAR","SEAT","SAME","SATE","STAR","STEM","TAME","TARE","TEAM","TEAR","TEAS","ARMS","TRAM","MAST","MART","REAM","MATES",
        "ARM","ART","ARE","EAR","ERA","EAT","ATE","TEA","MAR","RAM","RAT","TAR","MET","SET","SEA","SAT","TAM","REM",

        // ── CAMERA ───────────────────────────────────────────────────────────
        "CAMERA",
        "CREAM","MACER",
        "ACRE","AREA","CARE","RACE","REAM","CAME","MACE","ACME","MARE","CRAM","ACER","ARECA",
        "ACE","ARC","ARE","ARM","CAM","CAR","EAR","ERA","MAC","MAR","RAM",

        // ── POCKET ───────────────────────────────────────────────────────────
        "POCKET",
        "PECK","COPE","COKE","POET","POKE","TOCK","TOKE","TOPE","KETO","POCK","TOCO",
        "COP","COT","ECO","OPT","PET","POT","TOE","TOP","KOP",

        // ── APRICOT ──────────────────────────────────────────────────────────
        "APRICOT",
        "TROPIC","CAPTOR","ACTOR",
        "TOPIC","OPTIC","PATIO","RATIO","CAPRI",
        "COAT","TACO","ORCA","CROP","TRIO","PAIR","PART","PORT","TARP","TRAP","PACT","CART","PITA","RIOT","ATOP",
        "AIR","ARC","ART","CAP","CAR","COP","COT","OAR","OAT","PAR","PAT","PIT","POT","PRO","RAP","RAT","RIP","ROT","TAR","TAP","TIP","TOP","OCA",

        // ── BRIDGE ───────────────────────────────────────────────────────────
        "BRIDGE",
        "BIDE","BIRD","BRED","DIRE","GIRD","GRID","RIDE","RUED",
        "BID","BIG","DIG","GIB","GIG","RID","RIG","BED","RED","GEL",

        // ── CASTLE ───────────────────────────────────────────────────────────
        "CASTLE","CLEATS","SCLATE",
        "CASTE","CLEAT","ECLAT","LACES","SCALE","SLATE","STALE","TALES","LEAST","STEAL","TESLA","TACES",
        "CASE","CAST","CATS","LACE","LACS","LAST","LATE","LEST","SALT","SALE","SEAL","SEAT","SECT","SCAT","TACE","TALE","TALC","TEAL",
        "ACE","ATE","CAT","EAT","LAC","LAT","LET","SAC","SAT","SEA","SET","TAT","TEA","ELS","ALS",

        // ── DANCER ───────────────────────────────────────────────────────────
        "DANCER","CRANED","RANCED",
        "ACNED","CANED","CRANE","DANCE","NACRE",
        "CARD","CARE","DARE","DEAR","DEAN","EARN","NARC","RACE","RAND","READ","REND","CANE","ACNE","ARCED",
        "ACE","AND","ANE","ARC","CAN","CAR","DAN","DEN","END","ERA","EAR","NAE","RAN","RED","CAD","RAD",

        // ── FLOWER ───────────────────────────────────────────────────────────
        "FLOWER","FOWLER","WOLFER",
        "FLOE","FLEW","FLOE","FORE","FOWL","LORE","LOWE","ORLE","ROLE","ROLF","WORE","WOLF","OWLE",
        "ELF","EON","FLO","FOR","FOE","LOW","OWE","OWL","ROE","ROW","WOE","WOK",

        // ── GARDEN ───────────────────────────────────────────────────────────
        "GARDEN","RANGED","GRANED",
        "ANGER","DARER","GARNED","OARED","RANGE","GRAND","GANDER","DANGER",
        "AGED","DARE","DEAN","DRAG","EARN","GEAR","GRAD","GRAN","NARD","RAND","RANG","READ","REND",
        "AGE","AND","ARE","DAN","DEN","EAR","END","ERA","GAD","GAN","NAG","NAE","RAG","RAN","RED",

        // ── HUNTER ───────────────────────────────────────────────────────────
        "HUNTER","UNTHREW",
        "RUNE","HUNT","HURT","RUNT","THEN","THUN","TUNE","TURN","TERN","RENT","HERN",
        "HEN","HER","HUE","NUT","RUE","RUN","RUT","TEN","THE","TUN","URN","NET","NTH",

        // ── JUNGLE ───────────────────────────────────────────────────────────
        "JUNGLE",
        "LUNG","LUGE","JELL","LUNE","GULL","GULE","LUGE","JELL",
        "GEL","GEL","GUN","JUG","LUG","NUG","ULE",

        // ── MARKET ───────────────────────────────────────────────────────────
        "MARKET","TAMKER",
        "MAKER","TAKER","RAKE","MARE","MARK","MART","MEAT","MAKE","MATE","RATE","REAM","TAKE","TAME","TEAM","TERM","TREK","MATER",
        "ARC","ARE","ARM","ATE","EAR","EAT","ERA","MAR","MAT","MET","RAM","RAT","TAM","TAR","TEA","ERM",

        // ── NATURE ───────────────────────────────────────────────────────────
        "NATURE",
        "URATE","UREA","ANTRE",
        "ANTE","AUNT","EARN","NEAR","RANT","RATE","RUNE","RUNT","RUTA","TARE","TARN","TEAR","TUNE","TURN","TERN","RUNE","TUNA","RANT",
        "ANT","ARE","ATE","EAR","EAT","ERA","NAE","NUT","RAN","RAT","RUE","RUN","RUT","TAR","TAU","TEA","TEN","TUN","URN","NET",

        // ── OYSTER ───────────────────────────────────────────────────────────
        "OYSTER","STOREY","TOYERS","TYERS",
        "OYERS","ROSEY","STORY","STORE","TORES","TORSE","TYRES","RESTY",
        "RYES","ROTE","ROSY","SORT","SORE","TORE","TORY","TOEY","TOYS","TYES","OYES","YORE","RYES","ROTE",
        "OES","ORE","ORT","ROE","ROT","RYE","SET","SOT","SOY","STY","TOE","TOY","TYE","YES","YET",

        // ── PIRATE ───────────────────────────────────────────────────────────
        "PIRATE","PARTIE","TRAIPE",
        "IRATE","REPAID","TAPIR",
        "ATRIP","PARER","REDIA","RIPED","TAPER","TIARA","TRIPE",
        "PAIR","PARE","PART","PATE","PIER","PITA","RAPT","RATE","REAP","RIPE","TAPE","TARE","TEAR","TIER","TIRE","TRAP","TRIP",
        "AIR","APE","APT","ARE","ART","ATE","EAR","EAT","ERA","PAR","PAT","PEA","PIE","PIT","RAP","RAT","RIP","TAP","TAR","TEA","TIP",

        // ── QUARTZ ───────────────────────────────────────────────────────────
        "QUARTZ",
        "TZAR","TSAR","QUAT","RATU",
        "ART","QUA","RAT","TAR","TAT","TAU",

        // ── ROCKET ───────────────────────────────────────────────────────────
        "ROCKET",
        "TROKE","TOKER","OCKER",
        "COKE","CORE","CORK","ROTE","RECK","ROCK","TOCK","TOKE","TREK","TORE","RECTO",
        "COR","COT","ECO","ORE","ORT","ROE","ROT","TOE","TOK",

        // ── SILVER ───────────────────────────────────────────────────────────
        "SILVER","LIVERS","EVILS","RIVEL","VILER","VEILS",
        "LIVER","LIVES","RIVEL","RIELS","VEILS","VILER","VIELS",
        "EVIL","ISLE","IRES","LEIS","LIES","LIVE","RIEL","RILE","RISE","VEIL","VIES","VILE",
        "ELS","ILL","IRE","LEI","LIE","RIE","SIR","VIE",

        // ── TEMPLE ───────────────────────────────────────────────────────────
        "TEMPLE",
        "EMMET","MELT","MEET","PEEL","PELE","PELT","PETE","TEEM","TELE",
        "EEL","ELM","EME","LET","MET","PEE","PET","TEE",

        // ── UNFOLD ───────────────────────────────────────────────────────────
        "UNFOLD",
        "FOUND","FOND","FOUL","LOUD","LUND","DOUN","DUNE",
        "DON","DUO","FLU","FON","FUN","LOD","NUL","OLD","UDO","UNO",

        // ── VICTOR ───────────────────────────────────────────────────────────
        "VICTOR",
        "RICOT","TORIC","VIRCO",
        "COIR","CRIT","RIOT","ROTI","OTIC","VROT",
        "COR","COT","ORT","ROT","TIC","TOC","VIE",

        // ── WINDOW ───────────────────────────────────────────────────────────
        "WINDOW",
        "WINO","WIND","DINO","DOWN","DOIT",
        "DIN","DON","DOW","ION","NOD","NOW","OWN","WIN","WOD","WON",

        // ── FOREST ───────────────────────────────────────────────────────────
        "FOREST","FORTES","FOSTER","SOFTER",
        "FORES","FORTE","FRETS","FROST","STORE","TORES","TORSE",
        "FORE","FORT","FROE","FRET","ORES","REST","ROES","ROTE","ROTS","SERF","SORT","SORE","TORE",
        "FOR","FOE","FRO","OES","ORE","ORT","ROE","ROT","SET","SOT","TOE",

        // ── ANCHOR ───────────────────────────────────────────────────────────
        "ANCHOR","RANCHO","ARCHON",
        "NACHO","HORA","HORA","HORN","NARC","ROAN","ARCH","CHAR","CORN",
        "ARC","CAR","CAN","CON","COR","HON","NOR","OAR","OCA","ORC","RAH","RAN","ROC","HOC",

        // ── BANTER ───────────────────────────────────────────────────────────
        "BANTER","BANTER",
        "ANTRE","BRANT","TABEN",
        "ANTE","BARE","BARN","BATE","BEAN","BEAR","BEAT","BRAN","BRAT","EARN","RANT","RATE","TARE","TEAR","TERN","RENT",
        "ANE","ANT","ATE","BAN","BAR","BAT","BET","EAR","EAT","ERA","NAB","NAE","NET","RAN","RAT","TAB","TAN","TAR","TEA","TEN",

        // ── CARPET ───────────────────────────────────────────────────────────
        "CARPET","TRACER","CARET",
        "CAPER","CRAPE","RACER","TAPER","TRACE","REACT","CARTE","CRATE","CARET",
        "ACRE","APER","CARE","CARP","CART","PACE","PARE","PART","PATE","RACE","RAPT","RATE","REAP","RECTO","TACE","TAPE","TARE",
        "ACE","APE","APT","ARC","ARE","ART","ATE","CAP","CAR","CAT","EAR","EAT","ERA","PAR","PAT","PEA","RAP","RAT","TAP","TAR","TEA",

        // ── DONKEY ───────────────────────────────────────────────────────────
        "DONKEY",
        "DYKE","DOKE","NODE","DONE","YOKE","YOND","DYNE","DENY","DENO","OKEY",
        "DEN","DOE","DON","DYE","END","EON","KEY","NOD","ODE","ONE","YON",
    ]
}
