

var axios = require('axios')
var fs = require('fs')
//axios.defaults.baseURL = 'http://api.football-data.org'

const TEST_URL = ''
const API_ALL_MATCHES = 'http://api.football-data.org/v1/competitions/467/fixtures'
const API_MATCH1 = 'http://api.football-data.org/v1/fixtures/165069'
const OUTPUT_FILE = 'bet-data.csv'

const scrapeMatches = async () => {
    
    const result = await axios.get(API_ALL_MATCHES)
    const matches = result.data.fixtures

    // remove old output file
    fs.unlinkSync(OUTPUT_FILE)

    var numGroupMatches = 0
    for (let [i, match] of matches.entries()) {
        const UTCstring = match.date
        const UTC = Date.parse(UTCstring) / 1000
        const status = match.status
        const p1 = match.homeTeamName
        const p2 = match.awayTeamName
        const matchContext = getMatchContext(i, p1, p2)
        // get match API ID
        var urlSegments = match._links.self.href.split('/')
        const apiMatchId = urlSegments[urlSegments.length-1]
        
        console.log(i + "(" + apiMatchId + "): " + UTCstring + " (" + UTC + "), " + status + ", " + p1 + " VS " + p2 + " (" + matchContext + ")")
        writeLine(i, apiMatchId, UTC, p1, p2, matchContext)

        if (i == 47) {
            console.log("group matches over")
        }

        if (p1 != '') {
            numGroupMatches += 1
        }
    }
    console.log("numGroupMatches: " + numGroupMatches)
}


const writeLine = (matchId, matchApiId, matchStart, p1, p2, matchContext) => {
    const line = matchId + ',' + matchApiId + ',' + matchStart + ',' + p1 + ',' + p2 + ',' + matchContext + '\n'
    fs.appendFileSync(OUTPUT_FILE, line)
}


const getMatchContext = (i, p1, p2) => {
    if (i >= 48 && i < 56) {
        return "1/8 Final"
    }
    if (i >= 56 && i <60) {
        return "1/4 Final"
    }
    if (i == 60 || i == 61) {
        return "1/2 Final"
    }
    if (i == 62) {
        return "3rd Place"
    }
    if (i == 63) {
        return "Final"
    }
    return "Group " + getGroup(p1, p2)
}

// build group lookup object
const getGroupLookupObject = () => {
    let lines = fs.readFileSync('./players-and-groups.txt', 'utf8').split('\n')
    let lookup = {}
    
    lines.map(l => {
        arr = l.split(',')
        lookup[arr[0]] = arr[1]
    })
    return lookup
}

const getGroup = (p1, p2) => {
    if (p1 in lookup) {
        return lookup[p1]
    }
    return lookup[p2]
}


const lookup = getGroupLookupObject()
scrapeMatches().catch(console.error)

