class SugarPiece extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 4, picSize := new Vector2d( 0.015, 0.015 ), collisionSize := 0.015
	static canPickup := 1
	static isFood := 1
	heldBy := []
	
	pickedUpBy( elem ) {
		This.heldBy[ &elem ] := 1
		return This
	}
	
	droppedBy( elem ) {
		This.heldBy.delete( &elem )
		return This
	}
	
	getInfo() {
		return new This.SugarPieceInfo( This )
	}
	
	class SugarPieceInfo extends GraphicalElement.ElementInfo {
		getHeldBy() {
			nSugar := resolveRef( This )
			heldBy := []
			for elemPtr, void in nSugar.heldBy
				if ( ref := resolvePtr( elemPtr ).getInfo() ).isRef {
					heldBy.push( ref )
				}
			if heldBy.Length()
				return heldBy
		}
	}
	
}