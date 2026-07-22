from html import escape
from io import BytesIO
from textwrap import wrap
from zipfile import ZIP_DEFLATED, ZipFile


def result_text(result):
    return "\n\n".join(
        f"{title}\n{result.get(key, '')}"
        for title, key in [
            ("Transcript", "transcript"),
            ("Summary", "summary"),
            ("Coaching Feedback", "feedback"),
        ]
    )


def make_docx(result):
    body = "".join(
        f"<w:p><w:r><w:t>{escape(line) or ' '}</w:t></w:r></w:p>"
        for line in result_text(result).splitlines()
    )
    document = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>{body}<w:sectPr/></w:body></w:document>"""
    out = BytesIO()
    with ZipFile(out, "w", ZIP_DEFLATED) as docx:
        docx.writestr("[Content_Types].xml", """<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>""")
        docx.writestr("_rels/.rels", """<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>""")
        docx.writestr("word/document.xml", document)
    return out.getvalue()


def make_pdf(result):
    lines = []
    for line in result_text(result).splitlines():
        lines.extend(wrap(line, 95) or [""])

    def pdf_escape(line):
        return line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

    pages = [lines[i:i + 52] for i in range(0, len(lines), 52)] or [[]]
    objs = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        f"<< /Type /Pages /Kids [{' '.join(f'{3 + i * 2} 0 R' for i in range(len(pages)))}] /Count {len(pages)} >>",
    ]
    for i, page in enumerate(pages):
        content_id = 4 + i * 2
        content = "BT /F1 10 Tf 50 760 Td 14 TL " + " T* ".join(
            f"({pdf_escape(line)}) Tj" for line in page
        ) + " ET"
        objs.extend([
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {3 + len(pages) * 2} 0 R >> >> /Contents {content_id} 0 R >>",
            f"<< /Length {len(content)} >>\nstream\n{content}\nendstream",
        ])
    objs.append(
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    )
    pdf = "%PDF-1.4\n"
    offsets = []
    for i, obj in enumerate(objs, 1):
        offsets.append(len(pdf))
        pdf += f"{i} 0 obj\n{obj}\nendobj\n"
    xref = len(pdf)
    pdf += f"xref\n0 {len(objs)+1}\n0000000000 65535 f \n"
    pdf += "".join(f"{offset:010d} 00000 n \n" for offset in offsets)
    pdf += f"trailer << /Root 1 0 R /Size {len(objs)+1} >>\nstartxref\n{xref}\n%%EOF"
    return pdf.encode()
