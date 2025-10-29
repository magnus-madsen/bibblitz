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

/// Main function - processes BibTeX from input file to output file
def main(): Unit \ IO =
    let result = run {
        let (inputFile, outputFile) = parseCommandLineArgs();
        parseFetchAndWrite(inputFile, outputFile)
    } with Env.runWithIO
      with Exit.runWithIO
      with FileRead.runWithIO
      with FileWrite.runWithIO
      with Http.runWithIO
      with Logger.runWithIO;
    match result {
        case Ok(_) => ()
        case Err(err) => println("${err}")
    }

/// Parses command line arguments and returns input and output file paths
def parseCommandLineArgs(): (String, String) \ {Env, Exit, Logger} =
    match Env.getArgs() {
        case Nil => {
            Logger.info("No arguments provided. Using refs.json -> refs.bib.");
            ("refs.json", "refs.bib")
        }
        case inputFile :: outputFile :: Nil =>
            (inputFile, outputFile)
        case _ => {
            Logger.fatal("Usage: java -jar BibBlitz.jar [<input.json> <output.bib>]");
            Exit.exit(1)
        }
    }

/// Parses bibliography from input file, fetches BibTeX from CrossRef, and writes to output file
def parseFetchAndWrite(inputFile: String, outputFile: String): Unit \ {FileRead, FileWrite, Http, Logger} =
    match Parser.loadBibliography(inputFile) {
        case None => Logger.fatal("Could not parse '${inputFile}'.")
        case Some(refs) => {
            Logger.info("Fetching data from CrossRef.");
            match Bibtex.fetchAndFormat(refs) {
                case Ok(bibtex) => {
                    FileWrite.write({str = bibtex}, outputFile);
                    Logger.info("Wrote BibTeX entries to '${outputFile}'.")
                }
                case Err(err) => Logger.fatal("Error fetching references: '${err}'.")
            }
        }
    }