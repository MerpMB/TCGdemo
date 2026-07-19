class_name OpenPackResult
extends RefCounted
## Dictionary factories for the structured OpenPackService outcome. The payload
## stays serialization-friendly and does not depend on editor class caches.


static func success(opened_pack_id: String, opened_cards: Array[CardData]) -> Dictionary:
	return {
		"succeeded": true,
		"error_code": "",
		"message": "",
		"pack_id": opened_pack_id,
		"cards": opened_cards.duplicate(),
	}


static func failure(code: String, detail: String, requested_pack_id: String = "") -> Dictionary:
	return {
		"succeeded": false,
		"error_code": code,
		"message": detail,
		"pack_id": requested_pack_id,
		"cards": [],
	}