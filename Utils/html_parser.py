import sys
import json
import re

TAGS_TO_REMOVE = ["<black>", "<darkBlue>", "<darkGreen>", "<darkAqua>", "<darkRed>", "<darkPurple>", "<gold>", "<darkGray>", "<blue>", "<green>", "<aqua>", "<red>", "<lightPurple>", "<yellow>", "<white>"]

CLASS_PATTERN = re.compile(r'class=["\'](.*?)["\']')
STYLE_PATTERN = re.compile(r'style=["\'](.*?)["\']')
TOKEN_PATTERN = re.compile(r'(<span[^>]*>|</span>|[^<]+)')
TAG_PATTERN = re.compile("|".join(map(re.escape, TAGS_TO_REMOVE)))

COLOR_MAP = {
    "elements.neutral": "#FFAA00",
    "elements.earth": "#00AA00",
    "elements.thunder": "#FFFF55",
    "elements.water": "#55FFFF",
    "elements.fire": "#FF5555",
    "elements.air": "#FFFFFF",
}

FONT_NAMESPACES = {
    "font-ascii": "default",
    "font-default": "default",
    "font-common": "common",
    "font-five": "language/five",
    "font-wynnic": "language/wynnic",
    "font-high_gavelian": "language/high_gavelian",
}

def clean_html(text):
    # Sometimes the API includes color tags like <aqua> or <white> so we can just remove any
    cleaned_text = TAG_PATTERN.sub("", text)

    # It can also include the internal dictionary keys for colors so convert those to hex
    for key, value in COLOR_MAP.items():
        cleaned_text = cleaned_text.replace(key, value)

    return cleaned_text

def parse_html_to_json(html_string, default_color):
    if html_string.strip() == "</br>":
        return []

    parts = []
    styles = [{}]
    current_style = {}

    plain_text = ""

    matcher = TOKEN_PATTERN.finditer(html_string)

    for match in matcher:
        token = match.group()

        if token.startswith("<span"):
            if len(plain_text) != 0:
                parts.append(create_part(plain_text, current_style))
                plain_text = ""

            parent_style = styles[-1]
            new_style = {
                "color": parent_style.get("color", default_color)
            }

            class_matcher = CLASS_PATTERN.search(token)
            if class_matcher:
                font_name = class_matcher.group(1).strip()
                namespace = FONT_NAMESPACES.get(font_name, "default")
                new_style["font"] = namespace

            style_matcher = STYLE_PATTERN.search(token)
            if style_matcher:
                style = style_matcher.group(1)

                for style_entry in style.split(";"):
                    style_entry = style_entry.strip()

                    if len(style_entry) == 0:
                        continue

                    style_pair = style_entry.split(":")
                    style_key = style_pair[0].strip()
                    style_value = style_pair[1].strip()

                    if style_key == "text-decoration":
                        if style_value == "underline":
                            new_style["underline"] = True
                        elif style_value == "line-through":
                            new_style["strikethrough"] = True
                    elif style_key == "font-style":
                        if style_value == "italic":
                            new_style["italic"] = True
                    elif style_key == "font-weight":
                        if style_value == "bolder":
                            new_style["bold"] = True
                    elif style_key == "color":
                        new_style["color"] = style_value
                    elif style_key == "margin-left":
                        if style_value == "7.5px":
                            parts[-1]["margin-left"] = "thin"
                        elif style_value == "20px":
                            parts[-1]["margin-left"] = "large"

            styles.append(new_style)
            current_style = new_style
        elif token.startswith("</span>"):
            if len(plain_text) != 0:
                parts.append(create_part(plain_text, current_style))
                plain_text = ""

            if len(styles) != 0:
                styles.pop()

            parent_style = {} if not styles else styles[-1]

            current_style = parent_style
        else:
            plain_text += token

    if len(plain_text) != 0:
        parts.append(create_part(plain_text, current_style))

    return parts

def create_part(text, style):
    part = {"text": text}

    for key in ["bold", "italic", "underline", "strikethrough", "font", "color", "margin-left"]:
        if key in style:
            if key == "font" and style[key] == "default":
                continue

            part[key] = style[key]

    return part

def process_file(input_path, output_path, gear):
    with open(input_path, "r", encoding="utf-8") as infile:
        data = json.load(infile)

    if gear:
        for item_data in data.values():
            if "majorIds" in item_data:
                json_major_ids = {}

                for key, value in item_data["majorIds"].items():
                    cleaned = clean_html(value)
                    json_major_ids[key] = parse_html_to_json(cleaned, "#55FFFF")

                item_data["jsonMajorIds"] = json_major_ids
    else:
        for aspect, aspect_data in data.items():
            if "tiers" in aspect_data:
                for tier, tier_data in aspect_data["tiers"].items():
                    if "description" in tier_data:
                        clean_description = [clean_html(desc) for desc in tier_data["description"]]
                        tier_data["description"] = [parse_html_to_json(desc, "#AAAAAA") for desc in clean_description]

    with open(output_path, "w", encoding="utf-8") as outfile:
        json.dump(data, outfile, indent=2)

process_file(sys.argv[1], sys.argv[2], sys.argv[3] == "true")
