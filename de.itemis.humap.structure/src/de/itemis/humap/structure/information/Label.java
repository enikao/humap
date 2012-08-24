package de.itemis.humap.structure.information;

import org.eclipse.emf.ecore.EAttribute;

public class Label extends AbstractRecognizerInformation {
	public DataKind dataKind;
	public LabelKind labelKind;

	public EAttribute eAttribute;
	
	@Override
	public String getFQName() {
		if (!replacedInformations.isEmpty()) {
			return replacedInformations.iterator().next().getFQName();
		} else {
			return eAttribute.getName();
		}
	}
}
