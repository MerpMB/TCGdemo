extends Node
## Persistence boundary. This service owns storage only; application services
## decide business transactions and call save_game() when state must be stored.
## The versioned disk implementation is added in the next foundation phase.


func save_game() -> bool:
	return true


func load_game() -> bool:
	return true


func delete_save() -> bool:
	return true
