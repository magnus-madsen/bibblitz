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

mod Csl {
    use Json.JsonElement
    use Json.JsonElement.JsonObject
    use Json.FromJson
    use Json.FromJson.fromJsonAt
    use Json.getAtKey
    use Json.getAtKeyOpt
    use Json.Path
    use Json.Path.Path
    use Json.Path.{!!}
    use Json.JsonError
    use Json.JsonError.JsonError

    /// Represents a CSL-JSON entry
    pub enum Csl {
        case Csl({
            cslType = String,
            title = String,
            author = List[CslAuthor],
            doi = String,
            containerTitle = Option[String],
            publishedPrint = Option[CslDate],
            volume = Option[String],
            page = Option[String],
            publisher = Option[String]
        })
    }

    /// Represents a CSL-JSON author
    pub enum CslAuthor {
        case CslAuthor({
            given = Option[String],
            family = String
        })
    }

    /// Represents a CSL-JSON date
    pub enum CslDate {
        case CslDate({
            dateParts = List[List[Int32]]
        })
    }

    /// FromJson instance for CslAuthor
    instance FromJson[CslAuthor] {
        pub def fromJsonAt(p: Path, x: JsonElement): Result[JsonError, CslAuthor] = {
            forM (
                map <- fromJsonAt(p, x);
                family <- getAtKey(p, "family", map);
                givenOpt <- getAtKeyOpt(p, "given", map)
            ) yield {
                CslAuthor.CslAuthor({ given = givenOpt, family = family })
            }
        }
    }

    /// FromJson instance for CslDate
    instance FromJson[CslDate] {
        pub def fromJsonAt(p: Path, x: JsonElement): Result[JsonError, CslDate] = {
            forM (
                map <- fromJsonAt(p, x);
                dateParts <- getAtKey(p, "date-parts", map)
            ) yield {
                CslDate.CslDate({ dateParts = dateParts })
            }
        }
    }

    /// FromJson instance for Csl
    instance FromJson[Csl] {
        pub def fromJsonAt(p: Path, x: JsonElement): Result[JsonError, Csl] = {
            forM (
                map <- fromJsonAt(p, x);
                cslType <- getAtKey(p, "type", map);
                title <- getAtKey(p, "title", map);
                author <- getAtKey(p, "author", map);
                doi <- getAtKey(p, "DOI", map);
                containerTitleOpt <- getAtKeyOpt(p, "container-title", map);
                publishedPrintOpt <- getAtKeyOpt(p, "published-print", map);
                volumeOpt <- getAtKeyOpt(p, "volume", map);
                pageOpt <- getAtKeyOpt(p, "page", map);
                publisherOpt <- getAtKeyOpt(p, "publisher", map)
            ) yield {
                Csl.Csl({
                    cslType = cslType,
                    title = title,
                    author = author,
                    doi = doi,
                    containerTitle = containerTitleOpt,
                    publishedPrint = publishedPrintOpt,
                    volume = volumeOpt,
                    page = pageOpt,
                    publisher = publisherOpt
                })
            }
        }
    }
}
