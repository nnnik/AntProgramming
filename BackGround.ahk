class BackGround extends GraphicalElement {
	static picFile := "res\background.png", picLevel := 1
	picSize[] {
		get {
			return GameControl.fieldSize.mul( 1.1 )
		}
	}
}