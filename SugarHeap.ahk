class SugarHeap extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 2, picSize := new Vector2d( 0.05, 0.05 )
	static canPickup := 1
	
	onSpawn() {
		Random, durability, 400, 500
		This.pieces := durability
	}
	
	pickedUpBy( elem ) {
		piece := new SugarPiece( This.pos.clone() )
		if !( --This.pieces )
			This.despawn()
		return piece.pickedUpBy( elem )
	}
	
}