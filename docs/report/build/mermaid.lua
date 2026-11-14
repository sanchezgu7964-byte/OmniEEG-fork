function CodeBlock(el)
  if el.classes[1] == "mermaid" then
    local t = el.text:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
    return pandoc.RawBlock("html", '<pre class="mermaid">' .. t .. '</pre>')
  end
end
