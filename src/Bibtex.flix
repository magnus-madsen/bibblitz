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
    use Json.FromJson.fromJson
    use Json.JsonError
    use Parser.{Name, Doi}
    use Parser.Name.Name
    use Parser.Doi.Doi
    use Sanitize.sanitize
    use Csl.Csl
    use Csl.Csl.Csl
    use Csl.CslAuthor
    use Csl.CslAuthor.CslAuthor
    use Csl.CslDate
    use Csl.CslDate.CslDate

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

            let fields = List.filterMap(identity,
                Some("  title     = {${rec#title}}") ::
                Some("  author    = {${rec#author}}") ::
                rec#journal |> Option.map(j -> "  journal   = {${j}}") ::
                rec#year |> Option.map(y -> "  year      = {${y}}") ::
                rec#volume |> Option.map(v -> "  volume    = {${v}}") ::
                rec#publisher |> Option.map(p -> "  publisher = {${p}}") ::
                Some("  doi       = {${rec#doi}}") ::
                Nil
            );

            let body = String.intercalate(",\n", fields);
            "${typeStr}{${rec#key},\n${body}\n}"
    }

    /// Converts CSL-JSON to BibTeX entry
    pub def cslToBibTeX(key: String, cslJson: JsonElement): Result[JsonError, Bibtex] =
        forM (Csl(csl) <- fromJson(cslJson)) yield {
            let bibtexType = if (csl#cslType == "journal-article") BibtexType.Article
                             else if (csl#cslType == "paper-conference") BibtexType.InProceedings
                             else BibtexType.Misc;

            let authorVal = formatAuthors(csl#author);
            let year = csl#publishedPrint
                       |> Option.flatMap(extractYear);

            Bibtex.Bibtex({
                entryType = bibtexType,
                key = key,
                title = csl#title,
                author = authorVal,
                journal = csl#containerTitle,
                year = year,
                volume = csl#volume,
                pages = csl#page,
                publisher = csl#publisher,
                doi = csl#doi
            })
        }

    /// Fetches BibTeX entries for a list of name-DOI pairs and formats them as a combined string
    pub def fetchAndFormat(refs: List[(Name, Doi)]): Result[String, String] \ {Http, Logger} =
        let successes = processRefs(refs);
        let combined = combineBibTeX(successes);
        Ok(combined)

    /// Formats a single CSL author for BibTeX
    def formatAuthor(author: CslAuthor): String =
        let CslAuthor(a) = author;
        let given = a#given |> Option.getWithDefault("");
        "${a#family}, ${given}"

    /// Formats author list for BibTeX
    def formatAuthors(authors: List[CslAuthor]): String =
        let names = List.map(formatAuthor, authors);
        String.intercalate(" and ", names)

    /// Extracts year from CSL date
    def extractYear(date: CslDate): Option[String] =
        let CslDate(d) = date;
        forM (
            firstDate <- List.head(d#dateParts);
            year <- List.head(firstDate)
        ) yield Int32.toString(year)

    /// Combines multiple BibTeX entries into a single string
    def combineBibTeX(entries: List[Bibtex]): String =
        let strings = List.map(ToString.toString, entries);
        String.intercalate("\n\n", strings)

    /// Processes a list of name-DOI pairs and returns their BibTeX entries
    /// Logs immediately after each fetch completes with progress indicator
    def processRefs(refs: List[(Name, Doi)]): List[Bibtex] \ {Http, Logger} =
        let total = List.length(refs);
        let indexed = List.zipWithIndex(refs);
        List.filterMap(match (idx, (Name(name), Doi(doi))) ->
            match CrossRef.fetchBibTeX(name, doi) {
                case Ok(bibtex) => {
                    Logger.info("[${idx + 1}/${total}] Fetched '${name}'.");
                    Some(bibtex)
                }
                case Err(err) => {
                    Logger.warn("[${idx + 1}/${total}] Failed to fetch '${name}': ${err}");
                    None
                }
            },
            indexed
        )
}
