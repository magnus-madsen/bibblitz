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

mod Sanitize {
    use Bibtex.Bibtex
    use Bibtex.Bibtex.Bibtex

    /// Sanitizes a Bibtex entry by applying sanitization functions to relevant fields
    pub def sanitize(b: Bibtex): Bibtex =
        let Bibtex(rec) = b;
        Bibtex({
            entryType = rec#entryType,
            key = rec#key,
            title = sanitizeTitle(rec#title),
            author = sanitizeAuthor(rec#author),
            journal = rec#journal |> Option.map(sanitizeJournal),
            year = rec#year,
            volume = rec#volume,
            pages = rec#pages,
            publisher = rec#publisher,
            doi = rec#doi
        })

    /// Sanitizes a title string
    def sanitizeTitle(s: String): String = s

    /// Sanitizes an author string
    def sanitizeAuthor(s: String): String = s

    /// Sanitizes a journal string
    def sanitizeJournal(s: String): String = s
    
}
