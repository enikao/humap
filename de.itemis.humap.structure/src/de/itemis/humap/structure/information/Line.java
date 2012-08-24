package de.itemis.humap.structure.information;

import java.util.Iterator;

import org.eclipse.emf.ecore.EClass;

public class Line extends AbstractRecognizerInformation {
	public EClass eClass;
	
	@Override
	public String getFQName() {
		if (replacedInformations.size() == 1) {
			return replacedInformations.iterator().next().getFQName();
		} else if (replacedInformations.size() == 2) {
			Iterator<AbstractRecognizerInformation> iterator = replacedInformations.iterator();
			return iterator.next().getFQName() + " --> " + iterator.next().getFQName();
		} else {
			return eClass.getName();
		}
	}

}
