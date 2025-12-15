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

pub mod DoiResolver {

    /// Resolves a DOI to BibTeX by trying CrossRef first, then falling back to DataCite.
    /// This handles DOIs from different registration agencies (CrossRef for most publishers,
    /// DataCite for Dagstuhl/LIPIcs, Zenodo, etc.)
    pub def fetchBibTeX(name: String, doi: String): Result[String, Bibtex.Bibtex] \ Http =
        match CrossRef.fetchBibTeX(name, doi) {
            case Ok(bibtex) => Ok(bibtex)
            case Err(_) => DataCite.fetchBibTeX(name, doi)
        }

}
