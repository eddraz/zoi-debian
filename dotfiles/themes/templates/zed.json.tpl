{
  "$schema": "https://zed.dev/schema/themes/v0.1.0.json",
  "name": "ZOI Theme",
  "author": "ZOI Debian",
  "themes": [
    {
      "name": "ZOI Active",
      "appearance": "{{ mode }}",
      "style": {
        "background": "{{ background }}",
        "surface.background": "{{ lighter_background }}",
        "elevated_surface.background": "{{ dark_background }}",
        "border": "{{ muted }}",
        "border.focused": "{{ accent }}",
        "text": "{{ foreground }}",
        "text.muted": "{{ muted }}",
        "text.accent": "{{ accent }}",
        "element.active": "{{ accent }}",
        "element.selected": "{{ selection }}",
        "tab_bar.background": "{{ darker_background }}",
        "tab.inactive_background": "{{ darker_background }}",
        "tab.active_background": "{{ background }}",
        "status_bar.background": "{{ dark_background }}",
        "title_bar.background": "{{ darker_background }}",
        "toolbar.background": "{{ background }}",
        "editor.background": "{{ background }}",
        "editor.foreground": "{{ foreground }}",
        "editor.gutter.background": "{{ background }}",
        "editor.active_line.background": "{{ lighter_background }}",
        "editor.highlighted_line.background": "{{ selection }}",
        "editor.line_number": "{{ muted }}",
        "editor.active_line_number": "{{ accent }}",
        "syntax": {
          "comment": { "color": "{{ muted }}", "font_style": "italic" },
          "string": { "color": "{{ green }}" },
          "keyword": { "color": "{{ magenta }}" },
          "function": { "color": "{{ blue }}" },
          "type": { "color": "{{ yellow }}" },
          "number": { "color": "{{ orange }}" },
          "boolean": { "color": "{{ orange }}" },
          "operator": { "color": "{{ cyan }}" },
          "variable": { "color": "{{ foreground }}" },
          "property": { "color": "{{ blue }}" }
        }
      }
    }
  ]
}
