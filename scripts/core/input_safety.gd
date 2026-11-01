class_name InputSafety
extends RefCounted
## Cleans text typed by players or received from the internet before the
## game uses, shows, saves or sends it. Removes control characters and
## invisible / right-to-left trick characters, keeps lengths in bounds, and
## checks ids, numbers and web addresses against what the game expects.
##
## There is no SQL anywhere in the game or its Worker. If a SQL database is
## ever added, use bound parameters only: string filtering like this is NOT
## SQL injection prevention on its own.

## Characters that are removed from any text (besides the 0-31 control codes).
const HIDDEN_CHARS: Array[int] = [
	0x7f, 0x200b, 0x200c, 0x200d, 0x200e, 0x200f,
	0x202a, 0x202b, 0x202c, 0x202d, 0x202e,
	0x2066, 0x2067, 0x2068, 0x2069, 0xfeff, 0xfffd, 0xfffe, 0xffff,
]
## Characters that are never allowed in names (markup and code punctuation).
const NAME_BLOCKED := "<>[]{}\\\"'`;|=$%&*#@^~"


static func _hidden(code: int, keep_newlines: bool) -> bool:
	if code == 10 and keep_newlines:
		return false
	if code < 32 or (code >= 0x80 and code <= 0x9f):
		return true
	return HIDDEN_CHARS.has(code)


## Text with hidden characters removed, runs of spaces squeezed, trimmed,
## and cut to max_length. Newlines are kept only when keep_newlines is true.
static func clean_text(raw: String, max_length: int, keep_newlines := false) -> String:
	var cleaned := ""
	for index: int in raw.length():
		var code := raw.unicode_at(index)
		if code == 9:
			cleaned += " "
		elif code == 13:
			cleaned += "\n" if keep_newlines else " "
		elif not _hidden(code, keep_newlines):
			cleaned += String.chr(code)
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	while cleaned.contains("\n\n\n"):
		cleaned = cleaned.replace("\n\n\n", "\n\n")
	return cleaned.strip_edges().left(max_length).strip_edges()


## A survivor's or player's display name: clean text without markup or code
## punctuation (letters from any language, numbers, spaces, - _ . , ! ? ( )).
static func clean_name(raw: String, max_length: int) -> String:
	var cleaned := ""
	for letter: String in clean_text(raw, max_length * 2):
		if not NAME_BLOCKED.contains(letter):
			cleaned += letter
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.strip_edges().left(max_length).strip_edges()


## True for ids the game itself uses: lowercase letters, numbers, _ (1-40).
static func is_id(text: String) -> bool:
	if text.is_empty() or text.length() > 40:
		return false
	for letter: String in text:
		if not "abcdefghijklmnopqrstuvwxyz0123456789_".contains(letter):
			return false
	return true


## A whole number from outside data, kept between low and high (0 if not a number).
static func clamp_count(raw: Variant, low: int, high: int) -> int:
	if raw is int or raw is float:
		var value := float(raw)
		if is_nan(value):
			return low
		# Clamp before converting: a huge number would wrap around as a whole number.
		return int(clampf(value, float(low), float(high)))
	return low


## A date like "2026-11-01T01:53:00" (what the game saves), or "" if it isn't one.
static func clean_date(raw: Variant) -> String:
	var text := str(raw)
	var pattern := RegEx.new()
	pattern.compile("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{1,3})?Z?$")
	return text if pattern.search(text) != null else ""


## A plain email address (as the sign-in service sends it), or "".
static func clean_email(raw: Variant) -> String:
	var text := str(raw)
	if text.length() > 120:
		return ""
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
	return text if pattern.search(text) != null else ""


## True when `url` is an https address on `base` (our own Worker) under `path`.
static func is_own_url(url: String, base: String, path: String) -> bool:
	if base.is_empty() or not url.begins_with(base + path):
		return false
	if not (base.begins_with("https://") or base.begins_with("http://127.0.0.1")):
		return false
	return not url.contains("\"") and not url.contains("'") and not url.contains("<") and not url.contains(" ")
