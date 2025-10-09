/*
 * Copyright 2025 Magnus Madsen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

mod Parser {
    use Json.JsonElement
    use Json.JsonElement.{JsonObject, JsonString}

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
