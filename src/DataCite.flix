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

pub mod DataCite {
    use Util.Json
    use Net.Http
    use Net.HttpResponse

    /// Fetches DataCite metadata and converts to BibTeX for a single reference
    pub def fetchBibTeX(name: String, doi: String): Result[String, Bibtex.Bibtex] \ Http =
        forM (
            json <- fetchJson(doi);
            bibtex <- Option.toOk("Failed to convert to BibTeX", dataCiteToBibTeX(name, json))
        ) yield bibtex

    /// Constructs the DataCite API URL for fetching metadata
    def getUrl(doi: String): String =
        "https://api.datacite.org/dois/${doi}"

    /// Fetches metadata for a given DOI from DataCite
    def fetchJson(doi: String): Result[String, Json] \ Http =
        forM (
            resp <- Http.get(getUrl(doi)) |> Result.mapErr(e -> "${e}");
            json <- Json.parse(HttpResponse.body(resp))
                        |> Result.mapErr(e -> "Failed to parse JSON: ${e}")
        ) yield json

    /// Converts DataCite JSON to BibTeX entry
    /// DataCite has a different JSON structure than CrossRef
    def dataCiteToBibTeX(key: String, json: Json): Option[Bibtex.Bibtex] =
        match json {
            case Json.JObject(root) =>
                forM (
                    data <- JsonUtils.getJsonObject(root, "data");
                    attrs <- JsonUtils.getJsonObject(data, "attributes")
                ) yield {
                    let entryType = getResourceType(attrs);
                    let bibtexType = if (entryType == "JournalArticle") Bibtex.BibtexType.Article
                                     else if (entryType == "ConferencePaper") Bibtex.BibtexType.InProceedings
                                     else Bibtex.BibtexType.Misc;

                    let titleVal = getTitleFromDataCite(attrs) |> Option.getWithDefault("Unknown Title");
                    let authorVal = getAuthorsFromDataCite(attrs);
                    let doiVal = JsonUtils.getJsonString(attrs, "doi") |> Option.getWithDefault("");
                    let container = getContainerFromDataCite(attrs);
                    let year = getYearFromDataCite(attrs);
                    let volume = getVolumeFromDataCite(attrs);
                    let pages = getPagesFromDataCite(attrs);
                    let publisher = JsonUtils.getJsonString(attrs, "publisher");

                    Bibtex.Bibtex.Bibtex({
                        entryType = bibtexType,
                        key = key,
                        title = titleVal,
                        author = authorVal,
                        venue = container,
                        series = None,
                        year = year,
                        volume = volume,
                        pages = pages,
                        publisher = publisher,
                        doi = doiVal
                    })
                }
            case _ => None
        }

    /// Gets the resource type from DataCite attributes
    def getResourceType(attrs: Map[String, Json]): String =
        JsonUtils.getJsonObject(attrs, "types")
            |> Option.flatMap(t -> JsonUtils.getJsonString(t, "resourceTypeGeneral"))
            |> Option.getWithDefault("Other")

    /// Gets the title from DataCite titles array
    def getTitleFromDataCite(attrs: Map[String, Json]): Option[String] =
        forM (
            titles <- JsonUtils.getJsonArray(attrs, "titles");
            firstTitle <- List.head(titles)
        ) yield match firstTitle {
            case Json.JObject(t) => JsonUtils.getJsonString(t, "title") |> Option.getWithDefault("")
            case _ => ""
        }

    /// Gets authors from DataCite creators array
    def getAuthorsFromDataCite(attrs: Map[String, Json]): String =
        let creators = JsonUtils.getJsonArray(attrs, "creators") |> Option.getWithDefault(Nil);
        let names = List.filterMap(formatDataCiteAuthor, creators);
        String.intercalate(" and ", names)

    /// Formats a single DataCite author
    def formatDataCiteAuthor(authorJson: Json): Option[String] =
        match authorJson {
            case Json.JObject(obj) =>
                let family = JsonUtils.getJsonString(obj, "familyName") |> Option.getWithDefault("");
                let given = JsonUtils.getJsonString(obj, "givenName") |> Option.getWithDefault("");
                if (String.isEmpty(family)) {
                    // Try the combined name field
                    JsonUtils.getJsonString(obj, "name")
                } else {
                    Some("${family}, ${given}")
                }
            case _ => None
        }

    /// Gets container (journal/proceedings) title from DataCite
    def getContainerFromDataCite(attrs: Map[String, Json]): Option[String] =
        JsonUtils.getJsonObject(attrs, "container")
            |> Option.flatMap(c -> JsonUtils.getJsonString(c, "title"))

    /// Gets publication year from DataCite
    def getYearFromDataCite(attrs: Map[String, Json]): Option[String] =
        match JsonUtils.getJsonString(attrs, "publicationYear") {
            case Some(year) => Some(year)
            case None =>
                // Fallback: try to extract from dates array
                forM (
                    dates <- JsonUtils.getJsonArray(attrs, "dates");
                    firstDate <- List.head(dates)
                ) yield match firstDate {
                    case Json.JObject(d) =>
                        JsonUtils.getJsonString(d, "date")
                            |> Option.map(s -> String.slice(start = 0, end = 4, s))
                            |> Option.getWithDefault("")
                    case _ => ""
                }
        }

    /// Gets volume from DataCite container
    def getVolumeFromDataCite(attrs: Map[String, Json]): Option[String] =
        JsonUtils.getJsonObject(attrs, "container")
            |> Option.flatMap(c -> JsonUtils.getJsonString(c, "volume"))

    /// Gets pages from DataCite container
    def getPagesFromDataCite(attrs: Map[String, Json]): Option[String] =
        forM (
            container <- JsonUtils.getJsonObject(attrs, "container");
            firstPage <- JsonUtils.getJsonString(container, "firstPage");
            lastPage <- JsonUtils.getJsonString(container, "lastPage")
        ) yield "${firstPage}--${lastPage}"

}
