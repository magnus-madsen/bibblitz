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

    /// Represents a bibliographic reference name
    pub enum Name(String) with Eq, Order, ToString

    /// Represents a Digital Object Identifier
    pub enum Doi(String) with Eq, Order, ToString

    /// Loads name-DOI pairs from a JSON file
    pub def loadRefsFromFile(filename: String): Option[List[(Name, Doi)]] \ {FileRead, Logger} =
        let jsonContent = FileRead.read(filename);
        forM (
            refMap <- parseRefs(jsonContent);
            refs = Map.toList(refMap)
        ) yield {
            Logger.info("Successfully parsed ${filename} with ${List.length(refs)} references");
            refs
        }

    /// Parses a JSON string containing an object mapping names to DOIs
    def parseRefs(jsonString: String): Option[Map[Name, Doi]] =
        use Json.Parse.parse;
        use Option.map;
        parse(jsonString) |> map(match jsonElement ->
            match jsonElement {
                case JsonObject(obj) =>
                    obj |> Map.toList |> List.filterMap(extractDoiPair) |> List.toMap
                case _ => Map#{}
            }
        )

    /// Extracts a DOI pair from a JSON object entry
    def extractDoiPair(entry: (String, JsonElement)): Option[(Name, Doi)] =
        match entry {
            case (name, JsonString(doi)) => Some((Name.Name(name), Doi.Doi(doi)))
            case _ => None
        }
}
