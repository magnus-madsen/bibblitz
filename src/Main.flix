// DOI to BibTeX Converter using CrossRef API
// Fetches BibTeX entries for a list of DOIs and prints them to stdout

use Json.JsonElement
use Json.JsonElement.{JsonObject, JsonString, JsonArray, JsonNumber}

/// Fetches CSL-JSON metadata for a given DOI from CrossRef
def fetchCslJson(doi: String): Result[String, JsonElement] \ HttpWithResult =
    use Json.Parse.parse;
    let url = "https://api.crossref.org/works/${doi}/transform/application/vnd.citationstyles.csl+json";
    let headers = Map#{};
    match HttpWithResult.get(url, headers) {
        case Err(_) => Err("HTTP request failed")
        case Ok(Http.Response.Response(r)) => match parse(r#body) {
            case Some(json) => Ok(json)
            case None => Err("Failed to parse JSON")
        }
    }

/// Gets a string field from a JSON object
def getJsonString(obj: Map[String, JsonElement], key: String): Option[String] =
    forM (
        value <- Map.get(key, obj);
        str <- match value {
            case JsonString(s) => Some(s)
            case _ => None
        }
    ) yield str

/// Gets an array field from a JSON object
def getJsonArray(obj: Map[String, JsonElement], key: String): Option[List[JsonElement]] =
    forM (
        value <- Map.get(key, obj);
        arr <- match value {
            case JsonArray(a) => Some(a)
            case _ => None
        }
    ) yield arr

/// Extracts author name from CSL-JSON author object
def formatAuthor(authorJson: JsonElement): Option[String] =
    match authorJson {
        case JsonObject(obj) => {
            let given = getJsonString(obj, "given") |> Option.getWithDefault("");
            let family = getJsonString(obj, "family") |> Option.getWithDefault("");
            if (String.isEmpty(family)) None else Some("${family}, ${given}")
        }
        case _ => None
    }

/// Formats author list for BibTeX
def formatAuthors(authors: List[JsonElement]): String =
    let names = List.filterMap(formatAuthor, authors);
    String.intercalate(" and ", names)

/// Extracts year from date-parts array
def extractYear(dateJson: JsonElement): Option[String] =
    match dateJson {
        case JsonObject(obj) => {
            forM (
                dateParts <- getJsonArray(obj, "date-parts");
                firstDate <- List.head(dateParts);
                yearArray <- match firstDate {
                    case JsonArray(a) => Some(a)
                    case _ => None
                };
                yearElem <- List.head(yearArray)
            ) yield match yearElem {
                case JsonNumber(n) => BigInt.toString(BigDecimal.toBigInt(n))
                case _ => "0000"
            }
        }
        case _ => None
    }

/// Converts CSL-JSON to BibTeX entry
def cslToBibTeX(cslJson: JsonElement): Option[String] =
    match cslJson {
        case JsonObject(obj) => {
            let entryType = getJsonString(obj, "type") |> Option.getWithDefault("misc");
            let bibtexType = if (entryType == "journal-article") "@article"
                             else if (entryType == "paper-conference") "@inproceedings"
                             else "@misc";

            let doi = getJsonString(obj, "DOI") |> Option.getWithDefault("unknown");
            let key = doi;

            let title = getJsonString(obj, "title");
            let container = getJsonString(obj, "container-title");
            let year = getJsonArray(obj, "published-print")
                       |> Option.flatMap(List.head)
                       |> Option.flatMap(extractYear);
            let volume = getJsonString(obj, "volume");
            let pages = getJsonString(obj, "page");
            let publisher = getJsonString(obj, "publisher");

            let authors = getJsonArray(obj, "author") |> Option.map(formatAuthors);

            let fields = List.filterMap(identity,
                title |> Option.map(t -> "  title = {${t}}") ::
                authors |> Option.map(a -> "  author = {${a}}") ::
                container |> Option.map(c -> "  journal = {${c}}") ::
                year |> Option.map(y -> "  year = {${y}}") ::
                volume |> Option.map(v -> "  volume = {${v}}") ::
                pages |> Option.map(p -> "  pages = {${p}}") ::
                publisher |> Option.map(p -> "  publisher = {${p}}") ::
                Some("  doi = {${doi}}") ::
                Nil
            );

            let body = String.intercalate(",\n", fields);
            Some("${bibtexType}{${key},\n${body}\n}")
        }
        case _ => None
    }

/// Fetches CSL-JSON and converts to BibTeX for a single DOI
def fetchBibTeX(doi: String): Result[String, String] \ HttpWithResult =
    match fetchCslJson(doi) {
        case Err(e) => Err(e)
        case Ok(cslJson) => match cslToBibTeX(cslJson) {
            case Some(bibtex) => Ok(bibtex)
            case None => Err("Failed to convert to BibTeX")
        }
    }

/// Processes a list of DOIs and returns their BibTeX entries
def processDOIs(dois: List[String]): List[Result[String, String]] \ HttpWithResult =
    List.map(fetchBibTeX, dois)

/// Combines multiple BibTeX entries into a single string
def combineBibTeX(entries: List[String]): String =
    String.intercalate("\n\n", entries)

/// Parses a JSON string containing an object mapping names to DOIs
def parseRefs(jsonString: String): Option[Map[String, String]] =
    use Json.Parse.parse;
    forM (
        jsonElement <- parse(jsonString)
    ) yield match jsonElement {
        case JsonObject(obj) => {
            let pairs = Map.toList(obj);
            let doiPairs = List.filterMap(match (k, v) ->
                match v {
                    case JsonString(doi) => Some((k, doi))
                    case _ => None
                },
                pairs
            );
            List.toMap(doiPairs)
        }
        case _ => Map#{}
    }

/// Extracts all DOI values from a reference map
def extractDOIs(refMap: Map[String, String]): List[String] =
    Map.valuesOf(refMap)

/// Reads the refs.json file and returns its content
def readRefsFile(filename: String): Result[IoError, String] \ FileReadWithResult =
    FileReadWithResult.read(filename)

/// Loads DOIs from a JSON file
def loadDOIsFromFile(filename: String): Option[List[String]] \ FileReadWithResult =
    match readRefsFile(filename) {
        case Err(_) => None
        case Ok(jsonContent) => forM (
            refMap <- parseRefs(jsonContent)
        ) yield extractDOIs(refMap)
    }

/// Fetches and combines BibTeX entries for a list of DOIs
def fetchAllBibTeX(dois: List[String]): Result[String, String] \ HttpWithResult =
    let results = processDOIs(dois);
    let successes = List.filterMap(Result.toOption, results);
    let combined = combineBibTeX(successes);
    Ok(combined)

/// Prints BibTeX entries for DOIs loaded from refs.json
def printBibTeXFromFile(filename: String): Unit \ {FileReadWithResult, HttpWithResult, IO} =
    match loadDOIsFromFile(filename) {
        case None => println("Error: Could not read or parse ${filename}")
        case Some(dois) => {
            println("Fetching BibTeX entries for ${List.length(dois)} DOIs...");
            println("");
            match fetchAllBibTeX(dois) {
                case Ok(bibtex) => println(bibtex)
                case Err(err) => println("Error fetching DOIs: ${err}")
            }
        }
    }

/// Main function - reads DOIs from refs.json file
def main(): Unit \ IO =
    run {
        printBibTeXFromFile("refs.json")
    } with FileReadWithResult.runWithIO
      with HttpWithResult.runWithIO
