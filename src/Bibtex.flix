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

pub mod Bibtex {
    use Util.Json
    use Net.Http
    use Parser.{Name, Doi}
    use Parser.Name.Name
    use Parser.Doi.Doi
    use Sanitize.sanitize

    /// Represents a BibTeX entry with all possible fields
    pub enum Bibtex {
        case Bibtex({
            entryType = BibtexType,
            key = String,
            title = String,
            author = String,
            venue = Option[String],
            series = Option[String],
            year = Option[String],
            volume = Option[String],
            pages = Option[String],
            publisher = Option[String],
            doi = String
        })
    }

    /// Represents a BibTeX entry type
    pub enum BibtexType {
        case Article
        case InProceedings
        case Misc
    }

    /// ToString instance for Bibtex entries
    instance ToString[Bibtex] {
        pub def toString(b: Bibtex): String =
            let sanitized = sanitize(b);
            let Bibtex.Bibtex(rec) = sanitized;
            let typeStr = match rec#entryType {
                case BibtexType.Article => "@article"
                case BibtexType.InProceedings => "@inproceedings"
                case BibtexType.Misc => "@misc"
            };

            let venueKey = match rec#entryType {
                case BibtexType.InProceedings => "booktitle"
                case _                        => "journal"
            };

            let fields = List.filterMap(identity,
                Some("  title     = {{${rec#title}}}") ::
                Some("  author    = {${rec#author}}") ::
                rec#venue |> Option.map(v -> "  ${String.padRight(9, ' ', venueKey)} = {{${v}}}") ::
                rec#series |> Option.map(s -> "  series    = {{${s}}}") ::
                rec#year |> Option.map(y -> "  year      = {${y}}") ::
                rec#volume |> Option.map(v -> "  volume    = {${v}}") ::
                rec#publisher |> Option.map(p -> "  publisher = {{${p}}}") ::
                Some("  doi       = {${rec#doi}}") ::
                Nil
            );

            let body = String.intercalate(",\n", fields);
            "${typeStr}{${rec#key},\n${body}\n}"
    }

    /// Converts CrossRef works JSON to BibTeX entry
    pub def crossRefToBibTeX(key: String, json: Json): Option[Bibtex] =
        match json {
            case Json.JObject(obj) => {
                let entryType = JsonUtils.getJsonString(obj, "type") |> Option.getWithDefault("misc");
                let bibtexType = if (entryType == "journal-article") BibtexType.Article
                                 else if (entryType == "paper-conference" or entryType == "proceedings-article" or entryType == "book-chapter") BibtexType.InProceedings
                                 else BibtexType.Misc;

                // Required fields - must be present for a valid entry
                forM (
                    titleVal <- List.head(JsonUtils.getJsonStrings(obj, "title"));
                    authorsArray <- JsonUtils.getJsonArray(obj, "author");
                    doiVal <- JsonUtils.getJsonString(obj, "DOI")
                ) yield {
                    // CrossRef stores everything after the colon in a separate
                    // `subtitle` field (e.g. "JSand" / "complete client-side ..."),
                    // so the subtitle must be re-appended to get the full title.
                    let subtitles = JsonUtils.getJsonStrings(obj, "subtitle") |> List.filter(s -> not String.isEmpty(s));
                    let fullTitle = match List.head(subtitles) {
                        case Some(subtitle) => "${titleVal}: ${subtitle}"
                        case None           => titleVal
                    };
                    let authorVal = formatAuthors(authorsArray);
                    // For papers published in a series (e.g. Springer LNCS), CrossRef lists
                    // the series title before the actual venue title, so the venue is the
                    // last container title.
                    let containers = JsonUtils.getJsonStrings(obj, "container-title");
                    let venue = List.last(containers);
                    let series = if (List.length(containers) >= 2) List.head(containers) else None;
                    let year = ("published-print" :: "issued" :: Nil)
                               |> List.filterMap(k -> JsonUtils.getJsonObject(obj, k) |> Option.flatMap(extractYear))
                               |> List.head;
                    let volume = JsonUtils.getJsonString(obj, "volume");
                    let pages = JsonUtils.getJsonString(obj, "page");
                    let publisher = JsonUtils.getJsonString(obj, "publisher");

                    Bibtex.Bibtex({
                        entryType = bibtexType,
                        key = key,
                        title = fullTitle,
                        author = authorVal,
                        venue = venue,
                        series = series,
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

    /// Fetches BibTeX entries for a list of name-DOI pairs and formats them as a combined string
    pub def fetchAndFormat(refs: List[(Name, Doi)]): Result[String, String] \ {Http, Logger} =
        let successes = processRefs(refs);
        let combined = combineBibTeX(successes);
        Ok(combined)

    /// Extracts author name from CSL-JSON author object
    def formatAuthor(authorJson: Json): Option[String] =
        match authorJson {
            case Json.JObject(obj) => {
                let given = JsonUtils.getJsonString(obj, "given") |> Option.getWithDefault("");
                let family = JsonUtils.getJsonString(obj, "family") |> Option.getWithDefault("");
                if (String.isEmpty(family)) None else Some("${family}, ${given}")
            }
            case _ => None
        }

    /// Formats author list for BibTeX
    def formatAuthors(authors: List[Json]): String =
        let names = List.filterMap(formatAuthor, authors);
        String.intercalate(" and ", names)

    /// Extracts year from date-parts array
    def extractYear(obj: Map[String, Json]): Option[String] =
        def toArray(elem) = match elem {
            case Json.JArray(a) => Some(Vector.toList(a))
            case _ => None
        };
        def toNumber(elem) = match elem {
            case Json.JNumber(n) => Some(n)
            case _ => None
        };
        forM (
            dateParts <- JsonUtils.getJsonArray(obj, "date-parts");
            firstDate <- List.head(dateParts);
            yearArray <- toArray(firstDate);
            yearElem <- List.head(yearArray);
            yearNum <- toNumber(yearElem)
        ) yield BigInt.toString(BigDecimal.toBigInt(yearNum))

    /// Combines multiple BibTeX entries into a single string
    def combineBibTeX(entries: List[Bibtex]): String =
        let strings = List.map(ToString.toString, entries);
        String.intercalate("\n\n", strings)

    /// Processes a list of name-DOI pairs and returns their BibTeX entries
    /// Logs immediately after each fetch completes with progress indicator
    def processRefs(refs: List[(Name, Doi)]): List[Bibtex] \ {Http, Logger} =
        let total = List.length(refs);
        let width = String.length(Int32.toString(total));
        let indexed = List.zipWithIndex(refs);
        List.filterMap(match (idx, (Name(name), Doi(doi))) ->
            let paddedIdx = String.padLeft(width, '0', Int32.toString(idx + 1));
            match DoiResolver.fetchBibTeX(name, doi) {
                case Ok(bibtex) => {
                    Logger.info(RichString.text("[${paddedIdx}/${total}] ✓ Fetched '") + RichString.blue(name) + RichString.text("'."));
                    Some(bibtex)
                }
                case Err(err) => {
                    Logger.warn(RichString.text("[${paddedIdx}/${total}] ✗ Failed to fetch '") + RichString.blue(name) + RichString.text("' (${err})."));
                    None
                }
            },
            indexed
        )
}
