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

pub mod Sanitize {
    use Bibtex.Bibtex

    /// Sanitizes a Bibtex entry by applying sanitization functions to relevant fields
    pub def sanitize(b: Bibtex): Bibtex =
        let Bibtex.Bibtex(rec) = b;
        Bibtex.Bibtex({
            entryType = rec#entryType,
            key = rec#key,
            title = sanitizeTitle(rec#title),
            author = sanitizeAuthor(rec#author),
            venue = rec#venue |> Option.map(sanitizeVenue),
            series = rec#series |> Option.map(sanitizeVenue),
            year = rec#year,
            volume = rec#volume,
            pages = rec#pages,
            publisher = rec#publisher,
            doi = rec#doi
        })

    /// Sanitizes a title string
    def sanitizeTitle(s: String): String = escapeAmpersands(s)

    /// Sanitizes an author string by converting names written entirely in
    /// upper case (as published by e.g. Cambridge University Press) to title case
    def sanitizeAuthor(s: String): String =
        s |> String.words |> List.map(fixWordCase) |> String.unwords

    /// Converts a word to title case if it is written entirely in upper case.
    /// Words with fewer than two letters (e.g. initials) and words containing
    /// any lower case letter (i.e. correctly cased names) are kept as-is.
    def fixWordCase(w: String): String =
        let letters = String.toList(w) |> List.filter(Char.isLetter);
        let allUpper = List.length(letters) >= 2 and List.forAll(Char.isUpperCase, letters);
        if (allUpper) toTitleCase(w) else w

    /// Lowercases every letter that follows another letter, so each letter run
    /// keeps only its leading capital: "JEAN-PIERRE" becomes "Jean-Pierre"
    def toTitleCase(w: String): String =
        def step(acc: (String, Bool), c: Char): (String, Bool) = {
            let (res, prevIsLetter) = acc;
            let c1 = if (prevIsLetter) Char.toLowerCase(c) else c;
            (res + "${c1}", Char.isLetter(c))
        };
        String.toList(w) |> List.foldLeft(step, ("", false)) |> fst

    /// Sanitizes a venue string
    def sanitizeVenue(s: String): String = escapeAmpersands(s)

    /// Decodes HTML-escaped ampersands (as published by e.g. IEEE) and then
    /// escapes bare ampersands for BibTeX: "EuroS&amp;P" becomes "EuroS\&P"
    def escapeAmpersands(s: String): String =
        s |> String.replace(src = "&amp;", dst = "&")
          |> String.replace(src = "&", dst = "\\&")
    
}
