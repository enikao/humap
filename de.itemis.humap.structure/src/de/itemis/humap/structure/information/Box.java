package de.itemis.humap.structure.information;

import java.util.LinkedHashMap;
import java.util.Map;

import org.eclipse.emf.ecore.EClass;

public class Box extends AbstractRecognizerInformation {
	public int attributeCount;
	public int referenceCount;
	
	public EClass eClass;
	
	public Map<AbstractRecognizerInformation, Integer> compartmentMapping = new LinkedHashMap<AbstractRecognizerInformation, Integer>();
	
	@Override
	public String getFQName() {
		if (!replacedInformations.isEmpty()) {
			return replacedInformations.iterator().next().getFQName();
		} else {
			return eClass.getName();
		}
	}

}
