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

// DOI to BibTeX Converter using CrossRef API
// Fetches BibTeX entries for a list of DOIs and prints them to stdout

/// Processes BibTeX entries from input file and writes to output file
def processBibTeXFile(inputFile: String, outputFile: String): Unit \ {FileRead, FileWrite, Http, Logger} =
    match Parser.loadBibliography(inputFile) {
        case None => Logger.fatal("Could not parse ${inputFile}")
        case Some(refs) => {
            Logger.info("Fetching BibTeX entries for ${List.length(refs)} references...");
            match Bibtex.fetchAllBibTeXFromRefs(refs) {
                case Ok(bibtex) => {
                    FileWrite.write({str = bibtex}, outputFile);
                    Logger.info("Successfully wrote BibTeX entries to ${outputFile}")
                }
                case Err(err) => Logger.fatal("Error fetching references: ${err}")
            }
        }
    }

/// Helper function to run BibTeX processing with all effect handlers
def runBibTeXProcessing(inputFile: String, outputFile: String): Unit \ IO =
    match (run {
        processBibTeXFile(inputFile, outputFile)
    } with FileRead.runWithIO
      with FileWrite.runWithIO
      with Http.runWithIO
      with Logger.runWithIO) {
        case Ok(_) => ()
        case Err(err) => Logger.runWithIO(_ -> Logger.fatal("${err}"))
    }

/// Main function - processes BibTeX from input file to output file
def main(): Unit \ IO =
    let args = Environment.runWithIO(Environment.getArgs);
    match args {
        case Nil => {
            Logger.runWithIO(_ -> Logger.info("No arguments provided. Using defaults: refs.json -> refs.bib"));
            runBibTeXProcessing("refs.json", "refs.bib")
        }
        case inputFile :: outputFile :: Nil =>
            runBibTeXProcessing(inputFile, outputFile)
        case _ =>
            Logger.runWithIO(_ -> Logger.fatal("Usage: java -jar BibBlitz.jar [<input.json> <output.bib>]"))
    }
