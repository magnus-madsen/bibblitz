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

mod Bibtex {
    use Json.JsonElement
    use Json.JsonElement.{JsonObject, JsonString, JsonArray, JsonNumber}

    /// Extracts author name from CSL-JSON author object
    pub def formatAuthor(authorJson: JsonElement): Option[String] =
        match authorJson {
            case JsonObject(obj) => {
                let given = JsonUtils.getJsonString(obj, "given") |> Option.getWithDefault("");
                let family = JsonUtils.getJsonString(obj, "family") |> Option.getWithDefault("");
                if (String.isEmpty(family)) None else Some("${family}, ${given}")
            }
            case _ => None
        }

    /// Formats author list for BibTeX
    pub def formatAuthors(authors: List[JsonElement]): String =
        let names = List.filterMap(formatAuthor, authors);
        String.intercalate(" and ", names)

    /// Extracts year from date-parts array
    pub def extractYear(dateJson: JsonElement): Option[String] =
        match dateJson {
            case JsonObject(obj) => {
                forM (
                    dateParts <- JsonUtils.getJsonArray(obj, "date-parts");
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
    pub def cslToBibTeX(key: String, cslJson: JsonElement): Option[String] =
        match cslJson {
            case JsonObject(obj) => {
                let entryType = JsonUtils.getJsonString(obj, "type") |> Option.getWithDefault("misc");
                let bibtexType = if (entryType == "journal-article") "@article"
                                 else if (entryType == "paper-conference") "@inproceedings"
                                 else "@misc";

                let doi = JsonUtils.getJsonString(obj, "DOI") |> Option.getWithDefault("unknown");

                let title = JsonUtils.getJsonString(obj, "title");
                let container = JsonUtils.getJsonString(obj, "container-title");
                let year = JsonUtils.getJsonArray(obj, "published-print")
                           |> Option.flatMap(List.head)
                           |> Option.flatMap(extractYear);
                let volume = JsonUtils.getJsonString(obj, "volume");
                let pages = JsonUtils.getJsonString(obj, "page");
                let publisher = JsonUtils.getJsonString(obj, "publisher");

                let authors = JsonUtils.getJsonArray(obj, "author") |> Option.map(formatAuthors);

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

    /// Combines multiple BibTeX entries into a single string
    pub def combineBibTeX(entries: List[String]): String =
        String.intercalate("\n\n", entries)

    /// Processes a list of name-DOI pairs and returns their BibTeX entries
    pub def processRefs(refs: List[(String, String)]): List[Result[String, String]] \ Http =
        List.map(match (name, doi) -> CrossRef.fetchBibTeX(name, doi), refs)

    /// Fetches and combines BibTeX entries for a list of name-DOI pairs
    pub def fetchAllBibTeXFromRefs(refs: List[(String, String)]): Result[String, String] \ {Http, Logger} =
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
}
