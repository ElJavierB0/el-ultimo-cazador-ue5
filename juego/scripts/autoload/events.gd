extends Node
## Events: bus de eventos del juego (patrón Observador).
## Quien provoca algo solo emite la señal; el puntaje, la interfaz y el audio la escuchan
## sin conocerse entre sí.

signal coin_collected(position: Vector3)
signal potion_collected(position: Vector3)
signal bonfire_lit(bonfire: Bonfire)
signal enemy_touched(enemy: Enemy)
signal battle_started(enemy: Enemy)
signal battle_finished(result: String, enemy: Enemy)
signal hazard_touched(kind: String)
signal life_lost(lives_left: int)
signal door_touched()
signal level_completed()
signal shop_requested(bonfire: Bonfire)
signal transaction_done(transaction: Transaction)
signal score_changed(total: int)
signal hunter_changed()
signal message(text: String)
