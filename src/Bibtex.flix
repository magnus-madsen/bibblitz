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
    use Parser.{Name, Doi}
    use Parser.Name.Name
    use Parser.Doi.Doi
    use Sanitize.sanitize

    /// Represents a BibTeX entry type
    pub enum BibtexType {
        case Article
        case InProceedings
        case Misc
    }

    /// Represents a BibTeX entry with all possible fields
    pub enum Bibtex {
        case Bibtex({
            entryType = BibtexType,
            key = String,
            title = String,
            author = String,
            journal = Option[String],
            year = Option[String],
            volume = Option[String],
            pages = Option[String],
            publisher = Option[String],
            doi = String
        })
    }

    /// Extracts author name from CSL-JSON author object
    def formatAuthor(authorJson: JsonElement): Option[String] =
        match authorJson {
            case JsonObject(obj) => {
                let given = JsonUtils.getJsonString(obj, "given") |> Option.getWithDefault("");
                let family = JsonUtils.getJsonString(obj, "family") |> Option.getWithDefault("");
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

    /// Converts a Bibtex entry to its string representation
    pub def toString(b: Bibtex): String =
        let sanitized = sanitize(b);
        let Bibtex.Bibtex(rec) = sanitized;
        let typeStr = match rec#entryType {
            case BibtexType.Article => "@article"
            case BibtexType.InProceedings => "@inproceedings"
            case BibtexType.Misc => "@misc"
        };

        let fields = List.filterMap(identity,
            Some("  title = {${rec#title}}") ::
            Some("  author = {${rec#author}}") ::
            rec#journal |> Option.map(j -> "  journal = {${j}}") ::
            rec#year |> Option.map(y -> "  year = {${y}}") ::
            rec#volume |> Option.map(v -> "  volume = {${v}}") ::
            rec#pages |> Option.map(p -> "  pages = {${p}}") ::
            rec#publisher |> Option.map(p -> "  publisher = {${p}}") ::
            Some("  doi = {${rec#doi}}") ::
            Nil
        );

        let body = String.intercalate(",\n", fields);
        "${typeStr}{${rec#key},\n${body}\n}"

    /// Converts CSL-JSON to BibTeX entry
    pub def cslToBibTeX(key: String, cslJson: JsonElement): Option[Bibtex] =
        match cslJson {
            case JsonObject(obj) => {
                let entryType = JsonUtils.getJsonString(obj, "type") |> Option.getWithDefault("misc");
                let bibtexType = if (entryType == "journal-article") BibtexType.Article
                                 else if (entryType == "paper-conference") BibtexType.InProceedings
                                 else BibtexType.Misc;

                // Required fields - must be present for a valid entry
                forM (
                    titleVal <- JsonUtils.getJsonString(obj, "title");
                    authorsArray <- JsonUtils.getJsonArray(obj, "author");
                    doiVal <- JsonUtils.getJsonString(obj, "DOI")
                ) yield {
                    let authorVal = formatAuthors(authorsArray);
                    let container = JsonUtils.getJsonString(obj, "container-title");
                    let year = JsonUtils.getJsonArray(obj, "published-print")
                               |> Option.flatMap(List.head)
                               |> Option.flatMap(extractYear);
                    let volume = JsonUtils.getJsonString(obj, "volume");
                    let pages = JsonUtils.getJsonString(obj, "page");
                    let publisher = JsonUtils.getJsonString(obj, "publisher");

                    Bibtex.Bibtex({
                        entryType = bibtexType,
                        key = key,
                        title = titleVal,
                        author = authorVal,
                        journal = container,
                        year = year,
                        volume = volume,
                        pages = pages,
                        publisher = publisher,
                        doi = doiVal
                    })
                }
            }
            case _ => None
        }

    /// Combines multiple BibTeX entries into a single string
    def combineBibTeX(entries: List[Bibtex]): String =
        let strings = List.map(toString, entries);
        String.intercalate("\n\n", strings)

    /// Processes a list of name-DOI pairs and returns their BibTeX entries
    def processRefs(refs: List[(Name, Doi)]): List[Result[String, Bibtex]] \ Http =
        List.map(match (Name(name), Doi(doi)) -> CrossRef.fetchBibTeX(name, doi), refs)

    /// Fetches and combines BibTeX entries for a list of name-DOI pairs
    pub def fetchAllBibTeXFromRefs(refs: List[(Name, Doi)]): Result[String, String] \ {Http, Logger} =
        let results = processRefs(refs);
        let zipped = List.zip(refs, results);
        let successes: List[Bibtex] = List.filterMap(match ((Name(name), _doi), result) ->
            match result {
                case Ok(bibtex) => {
                    Logger.info("Successfully retrieved BibTeX for ${name}");
                    Some(bibtex)
                }
                case Err(_err) => {
                    Logger.warn("Failed to fetch ${name}");
                    None
                }
            },
            zipped
        );
        let combined = combineBibTeX(successes);
        Ok(combined)
}
