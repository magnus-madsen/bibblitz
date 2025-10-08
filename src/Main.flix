// DOI to BibTeX Converter using CrossRef API
// Fetches BibTeX entries for a list of DOIs and prints them to stdout

use Json.JsonElement
use Json.JsonElement.{JsonObject, JsonString, JsonArray, JsonNumber}

/// Fetches CSL-JSON metadata for a given DOI from CrossRef
def fetchCslJson(doi: String): Result[String, JsonElement] \ Http =
    use Json.Parse.parse;
    let url = "https://api.crossref.org/works/${doi}/transform/application/vnd.citationstyles.csl+json";
    let headers = Map#{};
    let Http.Response.Response(r) = Http.get(url, headers);
    match parse(r#body) {
        case Some(json) => Ok(json)
        case None => Err("Failed to parse JSON")
    }

/// Gets a string field from a JSON object
def getJsonString(obj: Map[String, JsonElement], key: String): Option[String] =
    match Map.get(key, obj) {
        case Some(JsonString(s)) => Some(s)
        case _ => None
    }

/// Gets an array field from a JSON object
def getJsonArray(obj: Map[String, JsonElement], key: String): Option[List[JsonElement]] =
    match Map.get(key, obj) {
        case Some(JsonArray(a)) => Some(a)
        case _ => None
    }

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
def cslToBibTeX(key: String, cslJson: JsonElement): Option[String] =
    match cslJson {
        case JsonObject(obj) => {
            let entryType = getJsonString(obj, "type") |> Option.getWithDefault("misc");
            let bibtexType = if (entryType == "journal-article") "@article"
                             else if (entryType == "paper-conference") "@inproceedings"
                             else "@misc";

            let doi = getJsonString(obj, "DOI") |> Option.getWithDefault("unknown");

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

/// Fetches CSL-JSON and converts to BibTeX for a single reference
def fetchBibTeX(name: String, doi: String): Result[String, String] \ Http =
    match fetchCslJson(doi) {
        case Err(e) => Err(e)
        case Ok(cslJson) => match cslToBibTeX(name, cslJson) {
            case Some(bibtex) => Ok(bibtex)
            case None => Err("Failed to convert to BibTeX")
        }
    }

/// Processes a list of name-DOI pairs and returns their BibTeX entries
def processRefs(refs: List[(String, String)]): List[Result[String, String]] \ Http =
    List.map(match (name, doi) -> fetchBibTeX(name, doi), refs)

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

/// Extracts all name-DOI pairs from a reference map
def extractRefs(refMap: Map[String, String]): List[(String, String)] =
    Map.toList(refMap)

/// Reads the refs.json file and returns its content
def readRefsFile(filename: String): String \ FileRead =
    FileRead.read(filename)

/// Loads name-DOI pairs from a JSON file
def loadRefsFromFile(filename: String): Option[List[(String, String)]] \ {FileRead, Logger} =
    let jsonContent = readRefsFile(filename);
    forM (
        refMap <- parseRefs(jsonContent);
        refs = extractRefs(refMap)
    ) yield {
        Logger.info("Successfully parsed ${filename} with ${List.length(refs)} references");
        refs
    }

/// Fetches and combines BibTeX entries for a list of name-DOI pairs
def fetchAllBibTeXFromRefs(refs: List[(String, String)]): Result[String, String] \ {Http, Logger} =
    let results = processRefs(refs);
    let zipped = List.zip(refs, results);
    let successes = List.filterMap(match ((name, _doi), result) ->
        match result {
            case Ok(bibtex) => {
                Logger.info("Successfully retrieved BibTeX for ${name}");
                Some(bibtex)
            }
            case Err(err) => {
                Logger.warn("Failed to fetch ${name}: ${err}");
                None
            }
        },
        zipped
    );
    let combined = combineBibTeX(successes);
    Ok(combined)

/// Processes BibTeX entries from input file and writes to output file
def processBibTeXFile(inputFile: String, outputFile: String): Unit \ {FileRead, FileWrite, Http, Logger} =
    match loadRefsFromFile(inputFile) {
        case None => Logger.fatal("Could not parse ${inputFile}")
        case Some(refs) => {
            Logger.info("Fetching BibTeX entries for ${List.length(refs)} references...");
            match fetchAllBibTeXFromRefs(refs) {
                case Ok(bibtex) => {
                    FileWrite.write({str = bibtex}, outputFile);
                    Logger.info("Successfully wrote BibTeX entries to ${outputFile}")
                }
                case Err(err) => Logger.fatal("Error fetching references: ${err}")
            }
        }
    }

/// Helper function to run BibTeX processing with all effect handlers
def runBibTeXProcessing(inputFile: String, outputFile: String): Unit \ IO =
    match (run {
        processBibTeXFile(inputFile, outputFile)
    } with FileRead.runWithIO
      with FileWrite.runWithIO
      with Http.runWithIO
      with Logger.runWithIO) {
        case Ok(_) => ()
        case Err(err) => Logger.runWithIO(_ -> Logger.fatal("${err}"))
    }

/// Main function - processes BibTeX from input file to output file
def main(): Unit \ IO =
    let args = Environment.runWithIO(Environment.getArgs);
    match args {
        case Nil => {
            Logger.runWithIO(_ -> Logger.info("No arguments provided. Using defaults: refs.json -> refs.bib"));
            runBibTeXProcessing("refs.json", "refs.bib")
        }
        case inputFile :: outputFile :: Nil =>
            runBibTeXProcessing(inputFile, outputFile)
        case _ =>
            Logger.runWithIO(_ -> Logger.fatal("Usage: java -jar BibBlitz.jar [<input.json> <output.bib>]"))
    }
