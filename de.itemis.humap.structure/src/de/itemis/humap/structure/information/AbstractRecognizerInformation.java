package de.itemis.humap.structure.information;

import java.util.ArrayList;
import java.util.List;

public abstract class AbstractRecognizerInformation {
	public BoundKind boundKind;
	
	public int lowerBound;
	public int upperBound;
	
	public List<AbstractRecognizerInformation> replacedInformations = new ArrayList<AbstractRecognizerInformation>();
	public List<AbstractRecognizerInformation> containedInformations = new ArrayList<AbstractRecognizerInformation>();
	
	public abstract String getFQName();
}
