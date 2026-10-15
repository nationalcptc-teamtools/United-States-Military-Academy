# Word design

Add an optional render_docx function consuming the same ordered document_blocks. Keep generate's existing positional parameters; append keyword-only docx=False and add --docx to CLI. Word and PDF are independently optional, Markdown always produced. Use lazy python-docx imports and the existing sibling staging directory/hash manifest.

Create a clean Letter/one-inch document with native Title/Heading styles, black headings, readable local Arial, cover metadata, static clickable contents and five chapter bookmarks. Use actual Word numbering definitions, including restarting ordered lists per block. Preserve source newlines as text breaks; never parse source markup. Use trusted PAGE field only and fixed internal navigation targets; no external relationships or active content. Word pagination belongs to Word and contents do not reuse PDF page numbers.

Compute handling via the existing function; repeated header includes the whole-document union and legacy warning. Fixed core metadata, remove default thumbnail/custom XML and unused external parts if present, remove revision-session IDs, and canonicalize ZIP entries/timestamps for stable hashes. This does not redact source content. Validate XML character compatibility before saving, then preserve all-or-nothing publication.

Master has no workbench module. Do not port or modify the separate published farm/workbench branches. No Word/LibreOffice process is a generation dependency; packaged rendering is preparation QA only.

