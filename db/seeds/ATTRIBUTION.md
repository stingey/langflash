# Seed Data Attribution

`common_nouns.csv` and `common_verbs.csv` are derived from the following
openly-licensed sources via the [doozan/spanish_data](https://github.com/doozan/spanish_data)
collection:

- **Frequency list** — derived from
  [hermitdave/FrequencyWords](https://github.com/hermitdave/FrequencyWords),
  licensed **CC-BY-SA 3.0**. Attribution: HermitDave, based on OpenSubtitles
  subtitle corpora.
- **Spanish → English definitions** — extracted from the English
  [Wiktionary](https://en.wiktionary.org/), licensed **CC-BY-SA 4.0**.
  Attribution: Wiktionary contributors.
- **Part-of-speech tags** — produced with
  [FreeLing](http://nlp.lsi.upc.edu/freeling) and combined into lemmas by
  [doozan/spanish_data](https://github.com/doozan/spanish_data), repo
  licensed **CC-BY 4.0**.

These CSVs are licensed under **CC-BY-SA 4.0** as a derivative work of
CC-BY-SA-licensed inputs. The rest of the LangFlash codebase is under a
separate license; the CC-BY-SA obligation applies only to these CSV files.

To regenerate, see `script/build_seed_csvs.rb`.

## Known quality caveats

The lists are auto-extracted and inherit Wiktionary's gloss-ordering quirks.
A small number of top-frequency entries have a non-ideal primary sense
because Wiktionary lists historical/archaic senses before common ones. Some
known examples you may want to edit by hand:

- `lecture,la clase` — Wiktionary lists "lecture" before "class (lesson)".
  More commonly translated as "class".
- `to summon,llamar` — commonly "to call".
- `to taste,gustar` — commonly "to like" (with its famous reversed-subject
  construction).
- `mister,el señor` — also "sir", "gentleman".

Feel free to edit these directly in the CSV; `CardSeedImporter` simply reads
the rows in file order.
