"""把报告 Markdown 转成 PDF：pandoc → HTML（MathML、mermaid）→ Chromium 打印。
用法：python3 build_pdf.py 输入.md 输出.pdf mermaid.min.js路径 [--clean]
--clean：去掉【用户判断】【助手推断】等起草标记与文首的状态说明。"""
import re, subprocess, sys, pathlib, tempfile
src, out, mjs = sys.argv[1:4]
clean = "--clean" in sys.argv
here = pathlib.Path(__file__).parent
md = pathlib.Path(src).read_text(encoding="utf-8")
if clean:
    md = re.sub(r"(?m)^> 状态：.*\n(> .*\n)*", "", md)
    md = re.sub(r"【(用户判断|助手推断|用户与合作者讨论的结论)】", "", md)
tmp = pathlib.Path(tempfile.mkdtemp())
(tmp / "in.md").write_text(md, encoding="utf-8")
html = tmp / "out.html"
subprocess.run(["pandoc", str(tmp / "in.md"), "-s", "--mathml", "--lua-filter", str(here / "mermaid.lua"),
                "--css", str(here / "style.css"), "--resource-path", str(pathlib.Path(src).resolve().parent), "--embed-resources", "--metadata", "title= ",
                "-o", str(html)], check=True)
h = html.read_text(encoding="utf-8")
h = h.replace("</body>", f"<script>{pathlib.Path(mjs).read_text(encoding='utf-8')}</script>"
              "<script>mermaid.initialize({startOnLoad:false,theme:'neutral',fontFamily:'WenQuanYi Zen Hei'});"
              "mermaid.run().then(()=>{document.body.setAttribute('data-done','1')});</script></body>")
html.write_text(h, encoding="utf-8")
subprocess.run(["node", str(here / "print_pdf.js"), html.as_uri(), out], check=True)
print("wrote", out)
