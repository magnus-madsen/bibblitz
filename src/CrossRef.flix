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

mod CrossRef {
    use Json.JsonElement

    /// Fetches CSL-JSON and converts to BibTeX for a single reference
    pub def fetchBibTeX(name: String, doi: String): Result[String, Bibtex.Bibtex] \ Http =
        use Json.JsonError.JsonError;
        forM (
            cslJson <- fetchJson(doi);
            bibtex <- Result.mapErr(match JsonError(path, expected) -> "Failed to convert to BibTeX at ${path}: expected ${expected}", Bibtex.cslToBibTeX(name, cslJson))
        ) yield bibtex

    /// Constructs the CrossRef API URL for fetching CSL-JSON metadata
    def getUrl(doi: String): String =
        "https://api.crossref.org/works/${doi}/transform/application/vnd.citationstyles.csl+json"

    /// Fetches CSL-JSON metadata for a given DOI from CrossRef
    def fetchJson(doi: String): Result[String, JsonElement] \ Http =
        use Json.Parse.parse;
        let Http.Response.Response(r) = Http.get(getUrl(doi), Map#{});
        Option.toOk("Failed to parse JSON", parse(r#body))

}
