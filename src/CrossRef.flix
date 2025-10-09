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

    /// Fetches CSL-JSON metadata for a given DOI from CrossRef
    def fetchCslJson(doi: String): Result[String, JsonElement] \ Http =
        use Json.Parse.parse;
        let url = "https://api.crossref.org/works/${doi}/transform/application/vnd.citationstyles.csl+json";
        let headers = Map#{};
        let Http.Response.Response(r) = Http.get(url, headers);
        match parse(r#body) {
            case Some(json) => Ok(json)
            case None => Err("Failed to parse JSON")
        }

    /// Fetches CSL-JSON and converts to BibTeX for a single reference
    pub def fetchBibTeX(name: String, doi: String): Result[String, String] \ Http =
        match fetchCslJson(doi) {
            case Err(e) => Err(e)
            case Ok(cslJson) => match Bibtex.cslToBibTeX(name, cslJson) {
                case Some(bibtex) => Ok(bibtex)
                case None => Err("Failed to convert to BibTeX")
            }
        }
}
