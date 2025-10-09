mod Parser {
    use Json.JsonElement
    use Json.JsonElement.{JsonObject, JsonString}

    /// Parses a JSON string containing an object mapping names to DOIs
    pub def parseRefs(jsonString: String): Option[Map[String, String]] =
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
    pub def extractRefs(refMap: Map[String, String]): List[(String, String)] =
        Map.toList(refMap)

    /// Reads the refs.json file and returns its content
    pub def readRefsFile(filename: String): String \ FileRead =
        FileRead.read(filename)

    /// Loads name-DOI pairs from a JSON file
    pub def loadRefsFromFile(filename: String): Option[List[(String, String)]] \ {FileRead, Logger} =
        let jsonContent = readRefsFile(filename);
        forM (
            refMap <- parseRefs(jsonContent);
            refs = extractRefs(refMap)
        ) yield {
            Logger.info("Successfully parsed ${filename} with ${List.length(refs)} references");
            refs
        }
}
