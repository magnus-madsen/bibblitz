# BibBlitz 📚⚡

A program to convert a JSON file into a `.bibtex` file using CrossRef and DataCite.

## Usage

Given a JSON file `refs.json` with the content:

```json
{
  "lutze2023": "10.1145/3607846",
  "lutze2024": "10.1145/3656393",
  "madsen2023": "10.4230/LIPIcs.ECOOP.2023.18",
  "madsen2025": "10.1145/3763126",
  "peytonjones2002": "10.1017/S0956796802004331"
}
```

You can create a `refs.bib` by running:

```sh
java -jar bibblitz.jar refs.json refs.bib
```

The program will fetch metadata from CrossRef and DataCite and display progress:

```
[Info] Parsed 'refs.json'. Found 5 DOIs.
[Info] Fetching data from CrossRef and DataCite.
[Info] [1/5] ✓ Fetched 'lutze2023'.
[Info] [2/5] ✓ Fetched 'lutze2024'.
[Info] [3/5] ✓ Fetched 'madsen2023'.
[Info] [4/5] ✓ Fetched 'madsen2025'.
[Info] [5/5] ✓ Fetched 'peytonjones2002'.
[Info] Wrote BibTeX entries to 'refs.bib'.
```

### Example Output

The generated `refs.bib` file will contain:

```bibtex
@article{lutze2023,
  title     = {{With or Without You: Programming with Effect Exclusion}},
  author    = {Lutze, Matthew and Madsen, Magnus and Schuster, Philipp and Brachthäuser, Jonathan Immanuel},
  journal   = {{Proceedings of the ACM on Programming Languages}},
  year      = {2023},
  volume    = {7},
  publisher = {{Association for Computing Machinery (ACM)}},
  doi       = {10.1145/3607846}
}

@article{lutze2024,
  title     = {{Associated Effects: Flexible Abstractions for Effectful Programming}},
  author    = {Lutze, Matthew and Madsen, Magnus},
  journal   = {{Proceedings of the ACM on Programming Languages}},
  year      = {2024},
  volume    = {8},
  publisher = {{Association for Computing Machinery (ACM)}},
  doi       = {10.1145/3656393}
}

@inproceedings{madsen2023,
  title     = {{Programming with Purity Reflection: Peaceful Coexistence of Effects, Laziness, and Parallelism}},
  author    = {Madsen, Magnus and van de Pol, Jaco},
  booktitle = {{LIPIcs, Volume 263, ECOOP 2023}},
  year      = {2023},
  volume    = {263},
  publisher = {{Schloss Dagstuhl – Leibniz-Zentrum für Informatik}},
  doi       = {10.4230/lipics.ecoop.2023.18}
}

@article{madsen2025,
  title     = {{Flix: A Design for Language-Integrated Datalog}},
  author    = {Madsen, Magnus and Lhoták, Ondřej},
  journal   = {{Proceedings of the ACM on Programming Languages}},
  year      = {2025},
  volume    = {9},
  publisher = {{Association for Computing Machinery (ACM)}},
  doi       = {10.1145/3763126}
}

@article{peytonjones2002,
  title     = {{Secrets of the Glasgow Haskell Compiler inliner}},
  author    = {Peyton Jones, Simon and Marlow, Simon},
  journal   = {{Journal of Functional Programming}},
  year      = {2002},
  volume    = {12},
  publisher = {{Cambridge University Press (CUP)}},
  doi       = {10.1017/s0956796802004331}
}
```
