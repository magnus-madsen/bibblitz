// DOI to BibTeX Converter using CrossRef API
// Fetches BibTeX entries for a list of DOIs and prints them to stdout

/// Processes BibTeX entries from input file and writes to output file
def processBibTeXFile(inputFile: String, outputFile: String): Unit \ {FileRead, FileWrite, Http, Logger} =
    match Parser.loadRefsFromFile(inputFile) {
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
