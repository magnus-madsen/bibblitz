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

pub mod CrossRef {
    use Util.Json
    use Net.Http
    use Net.HttpResponse

    /// Fetches CrossRef metadata and converts to BibTeX for a single reference
    pub def fetchBibTeX(name: String, doi: String): Result[String, Bibtex.Bibtex] \ Http =
        forM (
            json <- fetchJson(doi);
            bibtex <- Option.toOk("Failed to convert to BibTeX", Bibtex.crossRefToBibTeX(name, json))
        ) yield bibtex

    /// Constructs the CrossRef API URL for fetching work metadata.
    /// The raw works endpoint is used (rather than the CSL-JSON transform)
    /// because the transform discards all but the first container title,
    /// losing the venue of proceedings papers published in a series.
    def getUrl(doi: String): String =
        "https://api.crossref.org/works/${doi}"

    /// Fetches work metadata for a given DOI from CrossRef
    def fetchJson(doi: String): Result[String, Json] \ Http =
        forM (
            resp <- Http.get(getUrl(doi)) |> Result.mapErr(e -> "${e}");
            json <- Json.parse(HttpResponse.body(resp))
                        |> Result.mapErr(e -> "Failed to parse JSON: ${e}");
            message <- getMessage(json)
        ) yield message

    /// Extracts the `message` payload from a CrossRef API response
    def getMessage(json: Json): Result[String, Json] =
        match json {
            case Json.JObject(obj) => Map.get("message", obj) |> Option.toOk("Missing 'message' in CrossRef response")
            case _                 => Err("Unexpected CrossRef response")
        }

}
